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
ClassRep(map);
  while(--idx>=0) {
"GGG:%d,%x,%x\n",idx,EndianU16(map->end[idx]),EndianU16(starts[idx]);
    if(g>=EndianU16(map->end[idx])) {
      break;
    }
    good=EndianU16(map->end[idx]);
    goodi=idx;
  }
  idx=goodi;
"%d\n",idx;
  U16 start_code=EndianU16(starts[idx]);
"S:%d\n",start_code;
  U16 delta=EndianU16(deltas[idx]);
"D:%d\n",delta;
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
    "%x\n",use;
    if(use==4||use==0x301) {
      use=EndianU16((font+off+EndianU32(csub->offset))(U32*)[0]);
      "1.%d\n",use;
      if(use==12) {
        ret=CMapFmt13(font,off+EndianU32(csub->offset),uc,12);
      } else if(use==13) {
        ret=CMapFmt13(font,off+EndianU32(csub->offset),uc,13);
      }
    }else  if(use==3||use==0x30a) {
      use=EndianU16((font+off+EndianU32(csub->offset))(U32*)[0]);
      "2.%d\n",use;
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
"C:%d,%d\n",l,oilen;
  return oret;
}
U0 TTF_RenderChrSimple(CDC *dc,I64 x,I64 y,U8 *data,I64 cnt,F64 ppem) {
  U16 *ends=data,*oends=ends;
  data+=2*cnt;
"ASS:%d,%d\n",EndianU16(ends[0]),EndianU16(ends[1]);
  
  I64 ilen=EndianU16(data[-2](U16))+1,idx,flag,proced;
"%d\n",ilen;
//PressAKey;
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
  "%d\n",proced;
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
  DCFill;
  for(idx=0;idx!=ilen;idx++) {
   "%f,%f,%d\n",points[idx].x*ppem,points[idx].y*ppem,idx;
   GrLine(gr.dc,points[idx].x*300+200,-points[idx].y*300+200,
	points[idx+1].x*300+200,-points[idx+1].y*300+200
	);
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

U0 TTF_RenderChr(CDC *dc,I64 x,I64 y,U8 *file,I64 uc) {
  I64 g=TTF_UCToGlyph(file,uc);
"G:%d\n",g;
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
"%x\n",goff;
  CGlyphHdr *gh=TTF_GetTablePtr('glyf',file)+goff;
  if(EndianU16(gh->cont_cnt)>=0) {
//21 Savage Simple
"%n,%n,%n,%n\n",Fixed2F64(gh->x_min),Fixed2F64(gh->x_max),Fixed2F64(gh->y_min),Fixed2F64(gh->y_max);
   TTF_RenderChrSimple(dc,x,y,gh+1,EndianU16(gh->cont_cnt),ppem);
  } else {
//Complex 
  }
}
Cd(__DIR__);;;;
U8 *f=FileRead("mono.ttf");
TTF_RenderChr(NULL,0,0,f,'$$');