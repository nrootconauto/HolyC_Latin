class CTTFOffset {
  U32 type;
  U16 table_cnt;
  U16 pad,pad,pad;
};
class CTTFTable {
  U32 tag;
  U32 checksum;
  U32 offset;
  U32 size;
};
class CTTFCmapSub {
  U16 platform;
  U16 id;
  U32 offset;
};
class CTTFCmap {
  U16 ver;
  U16 sub_entries;
  CTTFCmapSub subs[0];
};
class CMap13 {
  U32 start;
  U32 end;
  U32 gl;
};
class CMap6 {
  U16 lang;
  U16 first;
  U16 cnt;
  U16 body[0];
};
I64 CMapFmt6(U8 *f,I64 table,U64 g) {
  CMap6 *map=f+table;
  if(0<=g-map->first<map->cnt)
    return map->body[g-map->first];
  return -1;
}
class CMap4 {
  U16 len;
  U16 pad;
  U16 segCntX2;
  U16 searchRange;
  U16 entrySelector;
  U16 rangeShift;
  U16 end[0];
};
I64 CMapFmt4(U8 *f,I64 table,U64 g) {
  CMap4 *map=f+table;
  I64 sx2=EndianU16(map->segCntX2);
  I64 idx=sx2/2,p;
  I64 good=0xffff,goodi=idx-1;
  U16 *starts=(&map->end)(U8*)+sx2+2;
  U16 *deltas=starts(U8*)+sx2;
  U16 *offsets=deltas(U8*)+sx2;
  while(--idx>=0) {
    if(g>=EndianU16(map->end[idx])) {
      break;
    }
    good=EndianU16(map->end[idx]);
    goodi=idx;
  }
  idx=goodi;
  U16 start_code=EndianU16(starts[idx]);
  U16 delta=EndianU16(deltas[idx]);
  U16 range_offset;
  range_offset=EndianU16(offsets[idx]);
  if(!range_offset) {
     return (g+delta)&0xffFF;
  }
  U16 id=EndianU16(offsets[idx+range_offset+g-start_code]);
  if(id)
    return (id+delta)&U16_MAX;
  return 0;
}
I64 CMapFmt13(U8 *f,I64 table,U64 g,I64 which) {
  U64 first,s,l;
  I64 i,len;
  I64 cnt=EndianU32((f+table)[12](U32*));
  CMap13 *map=f+table+16;
  while(--cnt>=0) {
    first=EndianU32(map->gl);
    s=EndianU32(map->start);
    l=EndianU32(map->end);
    if(s<=g<=l) {
      if(which==12) {
        return g-s+first;
      }else {
        return first;
      }
    }
    map++;
  }
  return -1;
}
U8 *TTF_GetTablePtr(U32 key,CTTFOffset *f,I64 *len=NULL) {
  I64 tcnt=f->table_cnt;
  CTTFTable *ballsack=f+1;
  while(--tcnt>=0) {
    if(key==ballsack->tag) {
      if(len) *len=EndianU32(ballsack->size);
      return f(U8*)+EndianU32(ballsack->offset);
    }
    ballsack++;
  }
  return NULL;
}
I64 TTF_UCToGlyph(U8 *font,U64 uc) {
  CTTFCmap *cmap=TTF_GetTablePtr('cmap',font);
  I64 ents=EndianU16(cmap->sub_entries);
  I64 off=cmap(U8*)-font;
  I64 ret=-1;
  I64 use,groups;
  while(--ents>=0) {
    CTTFCmapSub *csub=&cmap->subs[ents];
    use=EndianU16(csub->platform)<<8|EndianU16(csub->id);
    if(use==4||use==0x301) {
      use=EndianU16((font+off+EndianU32(csub->offset))(U32*)[0]);
      if(use==12) {
        ret=CMapFmt13(font,off+EndianU32(csub->offset),uc,12);
      } else if(use==13) {
        ret=CMapFmt13(font,off+EndianU32(csub->offset),uc,13);
      }
    }else  if(use==3||use==0x30a) {
      use=EndianU16((font+off+EndianU32(csub->offset))(U32*)[0]);
      if(use==6) {       
        ret=CMapFmt6(font,off+EndianU32(csub->offset)+2,uc);
      } else if(use==4)
        ret=CMapFmt4(font,off+EndianU32(csub->offset)+2,uc);
    }
    if(ret!=-1)
      return ret;
  }
  return -1;
}
U0 TTF_HMetrics(I64 g,U8* f,I64 *advance,I64 *left_bear) {
  U8 *hmtx=TTF_GetTablePtr("hmtx",f),*head=TTF_GetTablePtr("hhea",f);
  I64 long_hmtx=(head+34)(U16*)[0];
  I64 en;
  if(advance) *advance=0;
  if(left_bear) *left_bear=0;
  if(!hmtx) return;
  if (g<long_hmtx) {
//Forward [1,2,3.........]
    hmtx+=4*g;
    if(advance) *advance=*(hmtx(I16*));
    if(left_bear) *left_bear=hmtx(I16*)[1];
    return 0;
  } else {
//Backwars [.............7,8,9]
    en=long_hmtx*4;
    if(en<4) return;
    if(advance) *advance=(hmtx+en-4)(I16*)[0];
    if(left_bear) *left_bear=(hmtx+en-2*(g-long_hmtx))(I16*)[0];
  }
}
I16 class CFixed {
  I8 low,hi;
};
class CGlyphHdr {
  I16 cont_cnt;
  CFixed x_min;
  CFixed y_min;
  CFixed x_max;
  CFixed y_max;
};
#define SOF_CURVE 1
#define SOF_XSHORT 2
#define SOF_YSHORT 4
#define SOF_REPEAT 8
#define SOF_XSAME (1<<4)
#define SOF_YSAME (1<<5)

I64 SFlagsLen(U8 *f,I64 ilen) {
  U8 *of=f;
  while(ilen>0) {
   if(*f&SOF_REPEAT) {
     ilen-=f[1]+1;
     f+=2;
   } else { 
     ++f;
     --ilen;
   }
  }
  return f-of;
}
U8 *SGetInsts(U8 *f,I64 ilen) {
  U8 *of=f;
  I64 l=0,oilen=ilen;
  while(ilen>0) {
    if(*f&SOF_REPEAT) {
      l+=f[1]+1;
      ilen-=f[1]+1;
      f+=2;
    } else { 
      ++l;
      ++f;
      --ilen;
    }
  }
  f=of;
  ilen=oilen;  
  U8 *ret=CAlloc(l),*oret=ret;
  while(ilen>0) {
    if(*f&SOF_REPEAT) {
      MemSet(ret,f[0],f[1]+1);
      ret+=f[1]+1;
      ilen-=f[1]+1;
      f+=2;
    } else { 
      *ret=*f;
      ++ret;
      ++f;
      --ilen;
    }
  }
  return oret;
}
U0 RenderCon(CDC *dc,I64 x,I64 y,CD2 *points,U8 *flags,I64 len,F64 scale=16) {
  if(len<2) return; 
  I64 i;
  CD2 *control=NULL,*cur,*st=NULL,*en=NULL;
  CD2 *c2=NULL;
  CD3I32 bcontrols[4];
  dc=DCAlias(dc);
  dc->flags|=DCF_TRANSFORMATION;
  dc->color=RED;
  dc->thick=2;
  Mat4x4TranslationEqu(dc->r,x,y,0);
  bcontrols[0].z=0;
  bcontrols[1].z=0;
  bcontrols[2].z=0;
  bcontrols[3].z=0;
  for(i=0;i!=len+1;i++) {
    cur=&points[i%len];
    if(!control&&!(flags[i%len]&SOF_CURVE))
      control=cur; 
    else if(!c2&&!(flags[i%len]&SOF_CURVE))
      c2=cur;
    else if(!st&&flags[i%len]&SOF_CURVE)
      st=cur;
    else if(!en&&flags[i%len]&SOF_CURVE) {
      en=cur;
      if(!control) {
        GrLine3(dc,st->x*scale,-st->y*scale,0,en->x*scale,-en->y*scale,0);
      } else if(control&&!c2) {
        bcontrols[0].x=st->x*scale;
        bcontrols[0].y=-st->y*scale;
        bcontrols[1].x=control->x*scale;
        bcontrols[1].y=-control->y*scale;
        bcontrols[2].x=en->x*scale;
        bcontrols[2].y=-en->y*scale;
        Gr2Bezier3(dc,bcontrols);
        control=NULL;
      } else if(control&&c2) {
        bcontrols[0].x=st->x*scale;
        bcontrols[0].y=-st->y*scale;
        bcontrols[1].x=control->x*scale;
        bcontrols[1].y=-control->y*scale;
        bcontrols[2].x=c2->x*scale;
        bcontrols[2].y=-c2->y*scale;
        bcontrols[3].x=en->x*scale;
        bcontrols[3].y=-en->y*scale;
        Gr3Bezier3(dc,bcontrols);
        control=NULL;
	c2=NULL;
      }
      st=en;
      en=NULL;
    }
  }
  DCDel(dc);
}

U0 TTF_RenderChrSimple(CDC *dc,I64 x,I64 y,U8 *data,I64 cnt,F64 ppem,F64 scale=100) {
  U16 *ends=data,*oends=ends;
  data+=2*cnt;
  I64 last,next;
  I64 ilen=EndianU16(data[-2](U16))+1,idx,flag,proced,idx2;
  U8 *insts=data+2;
  data=insts+EndianU16(insts[-2](U16));
  U8 *flags=data;
  proced=SFlagsLen(flags,ilen);
  data+=proced;
  U8 *xcords=data;
  flags=SGetInsts(flags,ilen);
  CD2 *points=CAlloc(MSize(flags)*sizeof(CD2));
  F64 accum=0;
  I64 got;
  for(idx=0;idx<ilen;idx++) {
    flag=flags[idx];
    got=0;
    if(flag&SOF_XSHORT) {
      got=*xcords;
      if(!(flag&SOF_XSAME))
        got=-got;
      xcords++;
    } else if(!(flag&SOF_XSAME)) {
      got=EndianU16(xcords(U16*)[0]);
      got=got.i16[0];
      xcords+=2;
    }
    accum+=got;
    points[idx].x=accum/ppem;
  }
  ends=oends;
  data=xcords;
  accum=0;
  for(idx=0;idx<ilen;idx++) {
    flag=flags[idx];
    got=0;
    if(flag&SOF_YSHORT) {
      got=*xcords;
      if(!(flag&SOF_YSAME))
        got=-got;
      xcords++;
    } else if(!(flag&SOF_YSAME)) {
      got=EndianU16((xcords)(U16*)[0]);
      got=got.i16[0];
      xcords+=2;
    }
     accum+=got;
     points[idx].y=accum/ppem;
  }
  last=0;
  for(idx=0;idx!=cnt;idx++) {
    next=EndianU16(ends[idx]);
    RenderCon(dc,x,y,points+last,flags+last,next-last+1,scale);
    last=next+1;
  }
  Free(points);
  Free(flags);
}
F64 Fixed2F64(CFixed f) {
  f=EndianU16(f);
  if(f.hi>=0)
    return f.hi+f.low/ToF64(U8_MAX);
  return f.hi+f.low/ToF64(U8_MAX);
}
U0 TTF_RenderChr(CDC *dc,I64 x,I64 y,U8 *file,I64 uc,F64 scale=16) {
  I64 g=TTF_UCToGlyph(file,uc);
//  g=68+'y'-'a';
//g=68+1;
  if(g<0) return;
  U8 *head=TTF_GetTablePtr('head',file);
  U8 *loca=TTF_GetTablePtr('loca',file);
  F64 ppem=EndianU16((head+18)(U16*)[0]);
  if(!head) return;
  I64 loca_format=(head+50)(I16*)[0],width,goff;
  if(!loca_format) {
    width=2;
    goff=EndianU16(loca[width*g](U16))<<1;
  }else {
    width=4; 
    goff=EndianU32(loca[width*g](U32));
  }
  CGlyphHdr *gh=TTF_GetTablePtr('glyf',file)+goff;
  if(EndianU16(gh->cont_cnt)<=I16_MAX) {
//21 Savage Simple
   TTF_RenderChrSimple(dc,x,y,gh+1,EndianU16(gh->cont_cnt),ppem,scale);
  } else {
//Complex 
    Beep;
  }
}
#ifdef __CMD_LINE__
Cd(__DIR__);;;;
U8 *f=FileRead("mono.ttf");
DCFill;
WinMax;
#if 1
TTF_RenderChr(gr.dc,200,150,f,0x3b1,250);
TTF_RenderChr(gr.dc,400,150,f,0x3b9,250);
TTF_RenderChr(gr.dc,200,350,f,0x3c9,250);
TTF_RenderChr(gr.dc,400,350,f,0x3bd,250);
#else
TTF_RenderChr(gr.dc,200,150,f,'a',250);
TTF_RenderChr(gr.dc,400,150,f,'i',250);
TTF_RenderChr(gr.dc,200,350,f,'w',250);
TTF_RenderChr(gr.dc,400,350,f,'v',250);
#endif
#endif