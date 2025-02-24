#ifndef UTILS_H
#define UTILS_H 1
// a b c NULL (NULL terminated),ends at end of input or '.'
U8 *SkipWhitespace(U8 *s) {
  while(Bt(char_bmp_white_space,*s))
    s++;
  return s;
}
U8 **TokenizeSentence(U8 *str,U8 **en=NULL) {
  U8 *ostr=str;
  U8 **ret;
  I64 tcnt=0;
phase1:
  str=SkipWhitespace(str);
  switch(*str) {
    case '[':
    case ']':
    case ',':
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
      case ']':
	ret[tcnt]=StrNew("]");
	break;
      case ',':
	ret[tcnt]=StrNew(",");
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

#endif