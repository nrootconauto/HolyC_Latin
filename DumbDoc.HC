#include "GrammarAST"; //I64Set

class CDDMarker {
  I64 offset,len;
  I64 color;
  U8 *note;
}
class CDDLine:CQue {
  I64Set *string; //unicode codepoints
  I64Set *selected;
  I64Set *markers; //CDDMarker*
};

class CDDoc {
  I64Set *lines; //CDDLine
  I64 x,y;
};
I64 DDocCurU32(CDDoc *doc) {
  I64Set *lines=doc->lines;
  CDDLine *ln;
  I64 x=doc->x,y=doc->y;
  if(0<=y<lines->cnt) {
    ln=lines->body[y];
    if(ln->string) {
      if(0<=x<ln->string->cnt)
        return ln->string->body[x];
    }
    if(y!=lines->cnt-1)
	return '\n'; 
    return 0;
  }
  return -1;
}
CDDMarker *DDMarkerNew(CDDoc *doc,I64 len,I64 color,U8 *note) {
  I64Set *lines=doc->lines;
  CDDLine *ln;
  CDDMarker *mark=GCCAlloc(sizeof CDDMarker);
  if(0<=doc->y<lines->cnt) {
    ln=lines->body[doc->y];
    mark->offset=doc->x;
    mark->len=len;
    mark->color=color;
    mark->note=GCStrNew(note);
    ln->markers=I64SetAdd(ln->markers,mark);
  }
  return mark;
}
CDDoc *DDocNew() {
  CDDoc *ret=GCCAlloc(sizeof(CDDoc));
  ret->lines=I64SetAdd(NULL,GCCAlloc(sizeof(CDDLine)));
  return ret;
}

I64Set *I64SetRemoveAt(I64Set *s,I64 at) {
  if(0<=at<s->cnt) {
    MemCpy(&s->body[at],&s->body[at+1],(s->cnt-at-1)*8);
    --s->cnt;
  }
  return s;
}
I64Set *I64SetInsertAt(I64Set *s,I64 at,I64 v) {
  if(!s) return I64SetAdd(NULL,v);
  I64 i,ol=s->cnt,j;
  s=I64SetAdd(s,0,TRUE);
  i=s->cnt-at;
  for(j=0;j<i;++j) {
    s->body[ol-j]=s->body[ol-j-1];
  }
  s->body[at]=v;
  return s;
}
//Don't pass a newline to it
U0 LineInsertAt(CDDLine *ln,I64 at,I64 v) {
  I64Set *markers=ln->markers;
  CDDMarker *mark;
  I64 cnt;
  if(markers) {
    cnt=markers->cnt;
    while(--cnt>=0) {
      mark=markers->body[cnt];
      if(0<at-mark->offset<mark->len)
        ++mark->len;
      else if(mark->offset>=at)
	++mark->offset;
    }
  }
  ln->string=I64SetInsertAt(ln->string,at,v);
}

U0 LineRemoveAt(CDDLine *ln,I64 at) {
  I64Set *markers=ln->markers;
  CDDMarker *mark;
  I64 cnt;
  if(markers) {
    cnt=markers->cnt;
    while(--cnt>=0) {
      mark=markers->body[cnt];
      if(0<mark->offset-at<=mark->len)
        --mark->len;
      else if(mark->offset>at) {
	--mark->offset;
      } else if(mark->offset==at) {
	ln->markers=I64SetRem(ln->markers,mark);
      }
    }
  }
  ln->string=I64SetRemoveAt(ln->string,at);
}
U0 DDocUp(CDDoc *doc,I64 sc=0) {
   CDDLine *ln;
   if(!doc->y) return;
   ln=doc->lines->body[--doc->y];
   if(ln->string) {
     doc->x=MinI64(ln->string->cnt,doc->x);
   } else
     doc->x=0;
}
U0 DDocDown(CDDoc *doc,I64 sc=0) {
   CDDLine *ln;
   if(doc->y+1=doc->lines->cnt) return;
   ln=doc->lines->body[++doc->y];
   if(ln->string) {
     doc->x=MinI64(ln->string->cnt,doc->x);
   } else
     doc->x=0;
}
U0 DDocLeft(CDDoc *doc,I64 sc=0) {
   CDDLine *ln;
   if(sc&SCF_CTRL)
     doc->x=0;
   else if(--doc->x<0) {
     if(0<doc->y) {
	--doc->y;
        ln=doc->lines->body[doc->y];
	if(ln->string)
	  doc->x=ln->string->cnt;
	else doc->x=0;
     } else
	doc->x=0;
   }
}
U0 DDocRight(CDDoc *doc,I64 sc=0) {
   I64Set *lines=doc->lines;
   CDDLine *ln=lines->body[doc->y];
   if(sc&SCF_CTRL)
     doc->x=ln->string->cnt;
   else if(!ln->string||++doc->x>ln->string->cnt) {
     if(doc->y+1<lines->cnt) {
	++doc->y;
	doc->x=0;
     } else
	--doc->x;
   }
}
U0 DDocBackspace(CDDoc *doc) {
  I64Set *lines=doc->lines;
  CDDLine *ln=lines->body[doc->y],*ln2;
  I64Set *markers=ln->markers;
  CDDMarker *mark;
  I64 cnt,i,olen;
  if(doc->x||doc->y) {
    if(ln->string->cnt==0) {
      DDocLeft(doc);
      doc->lines=I64SetRem(doc->lines,ln);
    } else {
      if(doc->x==0) {
        doc->lines=I64SetRem(doc->lines,ln);
        ln2=doc->lines->body[--doc->y];
        if(ln2->string) {
	  olen=ln2->string->cnt;
        } else
	  olen=0;
        for(i=0;i!=ln->string->cnt;++i) {
	  ln2->string=I64SetAdd(ln2->string,ln->string->body[i],TRUE);
        }
	if(markers) {
	  cnt=markers->cnt;
	  while(--cnt>=0) {
	    mark=markers->body[cnt];
	    mark->offset+=olen;
	    ln2->markers=I64SetAdd(ln2->markers,mark);
	  }
        }
        doc->x=olen;
      } else {
        DDocLeft(doc);
        LineRemoveAt(doc->lines->body[doc->y],doc->x);
      }
    }
  }
}
U0 DDocInsChr(CDDoc *doc,I64 c) {
  I64Set *lines=doc->lines;
  CDDLine *ln=lines->body[doc->y];
  I64Set *markers=ln->markers;
  CDDMarker *mark;
  I64 cnt,i,at=doc->x;
  CDDLine *newln;
  if(c=='\n') {
    newln=GCCAlloc(sizeof(CDDLine));;
    doc->lines=I64SetInsertAt(doc->lines,doc->y+1,newln);
    if(ln->string) {
      for(i=doc->x;i!=ln->string->cnt;++i) {
        newln->string=I64SetAdd(newln->string,ln->string->body[i],TRUE);
      }
      ln->string->cnt=doc->x;
    }
    DDocRight(doc);
    if(markers) {
      cnt=markers->cnt;
      while(--cnt>=0) {
	mark=markers->body[cnt];
	if(mark->offset>=at) {
	  ln->markers=I64SetRem(ln->markers,mark);
	  newln->markers=I64SetAdd(newln->markers,mark);
	}
      }
    }
  } else {
    LineInsertAt(ln,at,c);
    DDocRight(doc);
  }
}
CDDoc *DDocLoad(U8 *text) {
  I64 cp;
  CDDoc *doc=DDocNew;
  while(cp=ReadUTF8(text,&text)) {
    DDocInsChr(doc,cp);
  }
  return doc;
}
U0 DDocPrint(CDDoc *doc,U8 *text,...) {
  I64 cp;
  U8 *o;
  o=text=StrPrintJoin(NULL,text,argc,argv);
  while(cp=ReadUTF8(text,&text))
    DDocInsChr(doc,cp);
  Free(o);
}
U8 *DDocSave(CDDoc *doc,I64 start_line=0,I64 end_line=-1) {
  if(end_line<0)
    end_line=doc->lines->cnt;
  I64 total=1,cnt,cnt2,cp;
  I64Set *lines=doc->lines;
  CDDLine *ln;
  U8 *ret,*ptr;
  for(cnt=start_line;cnt!=end_line;++cnt) {
    ln=lines->body[cnt];
    if(!ln->string)
      goto skip1;
    cnt2=ln->string->cnt;
    while(--cnt2>=0) {
      cp=ln->string->body[cnt2];
      if(0<=cp<=0x07F)
	total++;
      else if(0x80<=cp<=0x7FF)
	total+=2;
      else if(0x800<=cp<=0xFFFF)
	total+=3;
      else if(0x10000<=cp<=0x10FFFF)
        total+=4;
    }
skip1:;
    if(cnt+1!=lines->cnt)
      ++total;
  }
  ptr=CAlloc(total+1);
  ret=ptr;
  for(cnt=start_line;cnt!=end_line;++cnt) {
    ln=lines->body[cnt];
    if(!ln->string)
      goto skip2;
    for(cnt2=0;cnt2!=ln->string->cnt;++cnt2) {
      cp=ln->string->body[cnt2];
      if(0<=cp<=0x07F) {
        *ret++=cp;
      } else if(0x80<=cp<=0x7FF) {
        *ret=(cp&0b111111)|0b10000000;
	ret++;
	*ret=0b11000000|(cp>>6&0b111111);
	ret++;
      } else if(0x800<=cp<=0xFFFF) {
        *ret=(cp&0b111111)|0b10000000;
	ret++;
	*ret=0b10000000|(cp>>6&0b111111);
	ret++;
	*ret=0b11100000|(cp>>12&0b111111);
	ret++;
      } else if(0x10000<=cp<=0x10FFFF) {
        *ret=(cp&0b111111)|0b10000000;
	ret++;
	*ret=0b10000000|(cp>>6&0b111111);
	ret++;
	*ret=0b10000000|(cp>>12&0b111111);
	ret++;
	*ret=0b11110000|(cp>>18&0b111111);
	ret++;
      }
    }
skip2:;
    if(cnt+1!=lines->cnt)
      *ret++='\n';
	
  }
  return ptr;
}
I64 DDStrCmp(CDDoc *doc,U8 *str) {
  I64 cp,x=doc->x,y=doc->y,ret;
  while(cp=ReadUTF8(str,&str)) {
    ret=cp-DDocCurU32(doc);
    if(ret)
      break;
    DDocRight(doc);
    ret=0;
  }
  doc->x=x,doc->y=y;
  return ret;
}
Bool DDFind(CDDoc *doc,U8 *str) {
  I64 ox=doc->x,oy=doc->y;
  CDDLine *ln=doc->lines->body[doc->lines->cnt-1];
  I64 endx=0,endy=doc->lines->cnt-1;
  I64 cmp;
  if(ln)
    endx=ln->string->cnt;
  while(cmp=DDStrCmp(doc,str)) {
    DDocRight(doc);
    if(doc->x>=endx&&doc->y>=endy) {
      break;
    }
  }
  if(cmp)
    doc->x=ox,doc->y=oy;
  return cmp==0;
}


#if __CMD_LINE__
CDDoc *doc=DDocLoad("abc\ndef123\n456");
"%s\n",DDocSave(doc);
#endif