0#include "GarabageCollector.HC";
#ifndef UTILS_H
#define UTILS_H 1
// a b c NULL (NULL terminated),ends at end of input or '.'
U8 *SkipWhitespace(U8 *s) {
  while(Bt(char_bmp_white_space,*s))
    s++;
  return s;
}
U8 **TokenizeSentence(U8 *str,U8 **en=NULL,Bool include_punc=TRUE,Bool stop_at_period=TRUE) {
  U8 *ostr=str;
  U8 **ret;
  I64 tcnt=0;
phase1:
  str=SkipWhitespace(str);
  switch(*str) {
    case '[':
    case ']':
    case '=':
punc1:
      tcnt++;
      str++;
      break;
    default:
      if(Bt(char_bmp_alpha_numeric,*str)) {
        tcnt++;
        while(Bt(char_bmp_alpha_numeric,*str))
	  str++;
      } else
        str++; //???
      break;
    case '.':
    case ':':
    case ';':
    case ',':
      if(stop_at_period&&*str=='.')
	goto phase2_st;
      if(include_punc)
	goto punc1;
    case 0:
      goto phase2_st;
  }
  goto phase1;
phase2_st:
  ret=CAlloc(8*(tcnt+1));
  tcnt=0;
  str=ostr;
phase2:
  str=SkipWhitespace(str);
  switch(*str) {
    start:
      case '[':
	ret[tcnt]=StrNew("[");
	break;
      case '=':
	ret[tcnt]=StrNew("=");
	break;
      case ']':
	ret[tcnt]=StrNew("]");
	break;
    end:
      tcnt++;
      str++;
      break;
    default:
      if(Bt(char_bmp_alpha_numeric,*str)) {
	ostr=str;
        while(Bt(char_bmp_alpha_numeric,*str))
	  str++;
	ret[tcnt]=CAlloc(str-ostr+1); //Include NULL terminator
	MemCpy(ret[tcnt],ostr,str-ostr);
        tcnt++;
      } else
        str++; //???
      break;
    case '.':
    case ':': 
    case ';':
    case ',':
      if(stop_at_period&&*str=='.') {
	++str; //skip '.'
	goto fin;
      }
      if(include_punc) {
	ret[tcnt++]=MStrPrint("%c",*str);
	str++;
	break;
      }
     str++; //Ignore '.'
    case 0:
     goto fin;
  }
  goto phase2;
fin:
  if(en) *en=str;
  ret[tcnt]=NULL;
  return ret;
}

I64 ReadUTF8(U8 *st,U8 **en=NULL) {
  I64 ch=*st;
  if(0b10000000&ch==0) {
    if(en) *en=st+1;
    return ch;
  }
  if(0b11100000&ch==0b11000000) {
    if(en) *en=st+2;
    return (st[0]&0b11111)<<6|((st[1]&0b111111));
  }
  if(0b11110000&ch==0b11100000) {
    if(en) *en=st+3;
    return (st[0]&0b1111)<<12|(st[1]&0b111111)<<6|((st[2]&0b111111));
  }
  if(en) *en=st+4;
  return (st[1]&0b111)<<18|(st[1]&0b111111)<<12|(st[2]&0b111111)<<6|((st[3]&0b111111));  
}


U64 Transliterate(U64 ch) {
//https://en.wiktionary.org/wiki/Appendix:Unicode/Latin_Extended-A
  switch(ch) {
    case 0x153:
      ch='oe';
      break;
    case 0xe6:
    case 0xc6:
      ch='ae';
      break;
    case 0x100 ... 0x105:
      ch='a';
      break;
    case 0x106...0x10D:
      ch='c';
      break;
    case 0x10e...0x11b:
      ch='e';
      break;
    case 0x11f...0x123:
      ch='e';
      break;
    case 0x124...0x127:
      ch='e';
      break;
    case 0x128...0x135:
      ch='i';
      break;
    case 0x136...0x138:
      ch='k';
      break;
    case 0x139...0x142:
      ch='l';
      break;
    case 0x143...0x14b:
      ch='n';
      break;
    case 0x14c...0x151:
      ch='o';
      break;
    case 0x154...0x159:
      ch='e';
      break;
    case 0x15a...0x161:
      ch='s';
      break;
    case 0x162...0x167:
      ch='t';
      break;
    case 0x168...0x173:
      ch='u';
      break;
    case 0x174...0x175:
      ch='w';
      break;
    case 0x176...0x178:
      ch='y';
      break;
    case 0x179...0x17e:
      ch='z';
      break;
    default:
    if(!ch)
      return 0;
    if(!(31<=ch<=128))
      ch=CH_SHIFT_SPACE;
  }
  return ch;
}

U8 *TransliterateStr(U8 *s) {
  U8 *ret=MAlloc(2*StrLen(s)+1);
  U64 c;
  ret[0]=0;
  while(c=ReadUTF8(s,&s)) {
    CatPrint(ret,"%c",Transliterate(c));
  }
  return ret; 
}

CTask *mem_task=Fs;
class I64Set {
  I64 cnt;
  I64 body[0];
};
#include "GarbageCollector";
I64Set *I64SetAdd(I64Set *dst,I64 a,Bool repeats=FALSE){
  I64Set *tmp;
  I64 i;
  if(!dst) {
    dst=GCCAlloc(sizeof(I64Set)+8);
    dst->cnt=1;
    dst->body[0]=a;
    return dst;
  } 
  if(!repeats)
  for(i=0;i!=dst->cnt;i++) {
    if(dst->body[i]==a)
      return dst;
  }
  tmp=GCCAlloc(sizeof(I64Set)+8*(dst->cnt+1));
  tmp->cnt=dst->cnt+1;
  MemCpy(tmp->body,dst->body,dst->cnt*8);
  tmp->body[tmp->cnt-1]=a;
  GCFree(dst);
  return tmp;
}
I64Set *I64SetRem(I64Set *s,I64 v) {
  I64 idx,ptr=0,del=0;
  for(idx=0;idx!=s->cnt;idx++) {
    if(s->body[idx]!=v)
      s->body[ptr++]=s->body[idx];
    else
      del++;
  }
  s->cnt-=del;
  return s;
}

#endif