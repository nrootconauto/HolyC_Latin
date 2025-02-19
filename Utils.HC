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
