
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
U8 Transliterate(U64 ch) {
//https://en.wiktionary.org/wiki/Appendix:Unicode/Latin_Extended-A
  switch(ch) {
    case 0x100...0x105:
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
      ch='?';
  }
  return ch;
}

#define J_STR 1
#define J_NUM 2
#define J_ARRAY 3
#define J_NODE 4
class CJson {
  I64 type;
  union {
    U8 *str;
    F64 num;
    CHashTable *hash_table;
  }
  I64 cnt;
};

U8 *sqstring(U8 *ptr,U8 **en) {
  U8 *buf=MAlloc(1024);
  I64 ch=0,C;
  if(en) *en=ptr;
  if(*ptr!='\'') return NULL;
  ptr++;
  while(*ptr&&*ptr!='\'') {
    if(*ptr=='\\') {
      ptr++;
read_one:
      if(ch<1023)
        buf[ch++]=*(ptr++);
      else
	ptr++;
    } else
	goto read_one;
  }
  buf[ch]=0;
  if(en) *en=ptr+1;
  return buf;
}

U8 *dqstring(U8 *ptr,U8 **en) {
  U8 *buf=MAlloc(1024);
  I64 ch=0,C;
  if(en) *en=ptr;
  if(*ptr!='"') return NULL;
  ptr++;
  while(*ptr&&*ptr!='"') {
    if(*ptr=='\\') {
      ptr++;
read_one:
      if(ch<1023)
        buf[ch++]=*(ptr++);
      else
	ptr++;
    } else
	goto read_one;
  }
  buf[ch]=0;
  if(en) *en=ptr+1;
  return buf;
}


U8 *SkipWhitespace(U8 *s) {
  while(*s&&Bt(char_bmp_white_space,*s))
    s++;
  return s;
}
U8 *word(U8 *ptr,U8 **en) {
  U8 *buf=MAlloc(256);
  I64 ch=0;
  if(en) *en=ptr;
  if(!Bt(char_bmp_alpha_numeric,*ptr)) return NULL;
  while(Bt(char_bmp_alpha_numeric,*ptr))
    buf[ch++]=*ptr++;
  buf[ch]=0;
  if(en) *en=ptr;
  return buf;
}
class CIndexBlk {
    I64 inst_cnt;
    I64 inst_offsets[32];
    U8 *body['z'-'a'+1];
    I64 pad[(BLK_SIZE-8-8*('z'-'a'+1))/8];
};
CJson *ParseJson(U8 *st,U8 **en=NULL) {
  CJson *ret=NULL;
  U8 *name;
  CHashGeneric *g;
  st=SkipWhitespace(st);
  if(*st=='{') {
    ret=CAlloc(sizeof CJson);
    ret->type=J_NODE;
    ret->hash_table=HashTableNew(0x8);
    st=SkipWhitespace(st+1);
    while(*st!='}') {
      if(!*st) throw('JSON');
      switch(*st) {
	case '\'':
	name=sqstring(st,&st);
	break;
	case '"':
	name=dqstring(st,&st);
	break;
	default:
	name=word(st,&st);
	break;
      }
      if(!name) throw('JSON');
      st=StrFirstOcc(st,":");
      if(!st) throw('JSON');
      st++;
      g=CAlloc(sizeof CHashGeneric);
      g->str=name;
      g->type=HTT_WORD;
      g->user_data0=ParseJson(st,&st);
      HashAdd(g,ret->hash_table);
      st=StrFirstOcc(st,",}");
      if(!st) throw('JSON');
      if(*st==',') st++;
      st=SkipWhitespace(st);
    }
    st++;
  } else if(*st=='\'') {
    ret=CAlloc(sizeof CJson);
    ret->type=J_STR;
    ret->str=sqstring(st,&st);
  } else if(*st=='\"') {
    ret=CAlloc(sizeof CJson);
    ret->type=J_STR;
    ret->str=dqstring(st,&st);
  } else if(*st=='[') {
    st=SkipWhitespace(st+1);
    ret=CAlloc(sizeof CJson);
    ret->type=J_ARRAY;
    ret->hash_table=HashTableNew(0x10);
    while(*st!=']') {
      g=CAlloc(sizeof CHashGeneric);
      g->str=MStrPrint("%d",ret->cnt++);
      g->type=HTT_DICT_WORD;
      g->user_data0=ParseJson(st,&st);
      HashAdd(g,ret->hash_table);
      st=StrFirstOcc(st,",]");
      if(!st) throw('JSON');
      if(*st==',') st++;
      st=SkipWhitespace(st);
    }
    st++;
  } else {
    name=st;
    ret=CAlloc(sizeof CJson);
    ret->type=J_NUM;
    ret->num=Str2F64(st,&st);
    if(name==st)
      throw('JSON');
  }
  if(en) *en=st;
  if(!ret) throw('JSON');
  return ret;
}
U0 JsonDel(CJson *j) {
  I64 bucket;
  CHashGeneric *g;
  switch(j->type) {
    case J_STR:
      Free(j->str);
      break;
    case J_NUM:
      break;
    case J_NODE:
    case J_ARRAY:
      for(bucket=0;bucket<=j->hash_table->mask;bucket++)
        for(g=j->hash_table->body[bucket];g;g=g->next) {
	  JsonDel(g->user_data0);
        }
      HashTableDel(j->hash_table);
  }
  Free(j);
}
U0 DumpJson(U8 *d=NULL,CJson *j) {
  I64 bucket;
  CHashGeneric *g;
  Bool first=TRUE;
  switch(j->type) {
    case J_STR:
      CatPrint(d,"\"%Q\"",j->str);
      break;
    case J_NUM:
      CatPrint(d,"%n",j->num);
      break;
    case J_NODE:
    case J_ARRAY:
      CatPrint(d,"{");
      for(bucket=0;bucket<=j->hash_table->mask;bucket++)
        for(g=j->hash_table->body[bucket];g;g=g->next) {
	  if(!first) CatPrint(d,",");
	  CatPrint(d,"%s:",g->str);
	  DumpJson(d,g->user_data0);
	  first=FALSE;
        }
      CatPrint(d,"}");
  }
}
CJson *TrimJson(CJson *j,...) {
  I64 i;
  I64 bucket;
  CHashGeneric *g;
  if(j->type!=J_NODE) return j;
again:;
  for(bucket=0;bucket<=j->hash_table->mask;bucket++)
    for(g=j->hash_table->body[bucket];g;g=g->next) {
      for(i=0;i!=argc;i++) {
        if(!StrCmp(argv[i],g->str))
	  goto skip;
      }
      HashRemDel(g,j->hash_table);
      goto again;
skip:;
    }  
   return j;
} 
I64 GetWordPtr(I64 *max,CFile *file,U8*str,I64 ptr=0,Bool *new=NULL) {
  if(new) *new=FALSE;
  if(!*str) return ptr;
  I64 idx=ToUpper(*str)-'A';
  CIndexBlk dummy;
  FBlkRead(file,&dummy,ptr,1);
  if(new) *new=FALSE;
  if(!dummy.body[idx]) {
    dummy.body[idx]=*max;
    FBlkWrite(file,&dummy,ptr,1);
    MemSet(&dummy,0,sizeof CIndexBlk);
    FBlkWrite(file,&dummy,ptr=(*max)++,1);
    if(new) *new=TRUE;
    return GetWordPtr(max,file,str+1,ptr);
  }
  if(ptr>*max) throw('trie');
  return GetWordPtr(max,file,str+1,dummy.body[idx],new);
}
U0 MakeIndex(U8 *outname,U8 *in_name) {
  CIndexBlk dummy;
  U8 *optr=FileRead(in_name),*fptr,*ostr;
  Bool new;
  CFile *file;
  CHeapCtrl *oc=Fs->data_heap;
  CHashGeneric *g;
  CJson *j,*str;
  Del(outname);
  file=FOpen(outname,"w");
  MemSet(&dummy,0,sizeof CIndexBlk);
  FBlkWrite(file,&dummy);
  fptr=optr;
  I64 off=0,blk,sz=1,idx;
  do {
    fptr=SkipWhitespace(fptr);
    off=fptr-optr;
    if(!*fptr) break;
    Fs->data_heap=HeapCtrlInit(,NULL,0);
    j=ParseJson(fptr,&fptr);
    j=TrimJson(j,"senses","glosses","forms","tags","pos","word");
    if(j&&j->type==J_NODE) {
      g=HashFind("word",j->hash_table,-1);
      str=g->user_data0;
      ostr=str;
      for(idx=0;ReadUTF8(str);idx++) {
        ostr[idx]=Transliterate(ReadUTF8(str,&str));
      }
      ostr[idx]=0;
      str=ostr;
      if(str&&str->type=J_STR) {
//Ensure all charactors are alpha
        for(blk=0;blk!=StrLen(str->str);blk++) {
	  if(!('A'<=ToUpper(str->str[blk])<='Z'))
	   goto skip;
        }
        blk=GetWordPtr(&sz,file,str->str,,&new);
        FBlkRead(file,&dummy,blk,1);
	if(new) {
	  dummy.inst_cnt=1;
          dummy.inst_offsets[0]=off;
	} else {
	  if(dummy.inst_cnt<32)
            dummy.inst_offsets[dummy.inst_cnt++]=off;
	}
        FBlkWrite(file,&dummy,blk,1);
skip:;
      }
    }
    JsonDel(j);
    HeapCtrlDel(Fs->data_heap);
    Fs->data_heap=oc;
  } while(TRUE);
  file->de.size=sz<<BLK_SIZE_BITS;
  FClose(file); //Flush to disk to avoid long ram buffering
  Free(optr);
}
if(!FileFind(__DIR__"/INDEX.TRIE",,0)) {
  if(FileFind(__DIR__"/Latin.json.Z")) {
    PopUpOk("I will generate the HolyC dictionary files(Grab a beer).\n  This may take a few minutess\n");
    Copy(__DIR__"/Latin.json.Z",__DIR__"/Latin.json");
    MakeIndex(__DIR__"/INDEX.TRIE",__DIR__"/Latin.json");
  }
}

I64 GetWordOffset(U8 *word,U8 *index_file=__DIR__"/INDEX.TRIE",I64 inst=0) {
PrintI(index_file,word);
  CFile *file=FOpen(index_file,"r");
  CIndexBlk dummy;
  I64 blk=0,idx,off=-1;
  while(*word) {
    idx=ToUpper(*word)-'A';
    FBlkRead(file,&dummy,blk,1);    
    if(!dummy.body[idx]) 
      break;
    blk=dummy.body[idx];
    word++;
  }
  if(!*word)  {
    FBlkRead(file,&dummy,blk,1);
    off=dummy.inst_offsets[inst];
    if(!off) off=-1;
  }
  FClose(file);
  return off;
}
U8 *_GetWordString(U8 *word,U8 *json_file=__DIR__"/Latin.json",U8 *index_file=__DIR__"/INDEX.TRIE",I64 inst=0) {
  I64 off=GetWordOffset(word,index_file,inst),off2;
  if(off==-1) return NULL;
  U8 buffer[0x10000],fbuf[BLK_SIZE],*ret,*tmp;
  I64 bo=0;
  CFile *file=FOpen(json_file,"r");
  buffer[bo]=0;
loop:
  FBlkRead(file,fbuf,off2=off>>BLK_SIZE_BITS);
  off2<<=BLK_SIZE_BITS;
  if(off!=off2) {
    MemCpy(buffer+bo,fbuf+off-off2,BLK_SIZE-(off-off2));
    bo+=BLK_SIZE-(off-off2);
    off=off2+BLK_SIZE;
    buffer[bo]=0;
  } else {
    MemCpy(buffer+bo,fbuf,BLK_SIZE);
    bo+=BLK_SIZE;
    off=off2+BLK_SIZE;
    buffer[bo]=0;
  }
  if(!StrOcc(buffer,'\n')) {
    goto loop;
  } else *StrFirstOcc(buffer,"\n")=0;
  FClose(file);
  return StrNew(buffer);
}
U8 *GetWordString(U8 *word,U8 *json_file=__DIR__"/Latin.json",U8 *index_file=__DIR__"/INDEX.TRIE",I64 inst=0)  {
  U8 *tmp=_GetWordString(word,json_file,index_file,inst);
  if(!tmp) {
    return NULL;
  }
  U8 *otmp=tmp;
  U8 bo,*ret=MAllocIdent(tmp);
  I64 off=0;
  while(bo=Transliterate(ReadUTF8(tmp,&tmp))) {
    ret[off++]=bo;
  }
  ret[off++]=bo;
  Free(otmp);
  return ret;
}

CJson *GetJsonMember(CJson *j,U8 *member,I64 type=-1) {
  CHashGeneric *g;
  if(j->type==J_ARRAY||j->type==J_NODE) {
    g=HashFind(member,j->hash_table,-1);
    if(g) {
      j=g->user_data0;
      if(type==-1) return j;
      else if(type==j->type) return j;
    }
  }
  return NULL;
}
U8 *GetBaseWord(U8 *word,I64 inst=0) {
  U8 *ws=GetWordString(word);
  if(!ws) return NULL;
  U8 buf[STR_LEN];
  I64 idx,idx2;
  CJson *j=ParseJson(ws,NULL),*s0,*s,*f,*t;
  Free(ws);
  if(s0=GetJsonMember(j,"senses",J_ARRAY)) {
    if(s=GetJsonMember(s0,StrPrint(buf,"%d",inst),J_NODE)) {
      f=GetJsonMember(s,"form_of",J_ARRAY);
      if(f) {
        for(idx=0;t=GetJsonMember(f,StrPrint(buf,"%d",idx),J_NODE);idx++) {
	  if(t) t=GetJsonMember(t,"word",J_STR);
	  if(t) {
	    word=StrNew(t->str);
	    JsonDel(j);  
	    return word;
	  }
        }
      }
    }
  }
  JsonDel(j);
  if(inst)
    return NULL;
  return StrNew(word);
}
Bool IsFormOf(U8 *who,U8 *who2) {
  I64 i,i2;
  U8 *b,*b2,ret=FALSE;
  for(i=0;b=GetBaseWord(who,i);i++) {
    for(i2=0;b2=GetBaseWord(who,i2);i2++) {
      if(!StrCmp(b,b2))
	ret=TRUE;
      Free(b2);
    }
    Free(b);
  }
  return ret;
}
extern U8 *GetTranslation(U8*,Bool recurse=FALSE);
U8 *SmallDefinition(U8 *def) {
  if(!def) return def;
  U8 buf[STR_LEN],*bptr=buf,*want;
  Bool changed=TRUE;
  I64 len1,len2;
  def=StrNew(def);
  if(want=StrIMatch("conjugation of",def)) {
    StrScan(want,"conjugation of %s:",&bptr);
    return GetTranslation(buf);
  }
  if(want=StrIMatch("inflection of",def)) {
    StrScan(want,"inflection of %s:",&bptr);
    return GetTranslation(buf);
  }
  if(want=StrIMatch("alternative spelling of",def)) {
    StrScan(want,"alternative spelling of %s:",&bptr);
    return GetTranslation(buf);
  }
  while(changed) {
    changed=FALSE;
    U8 *first=StrFirstOcc(def,"("),*last;
    if(first) {
      if(last=StrFirstOcc(first,")")) {
        StrCpy(first,last+1);
        changed=TRUE;
      }
    }
    if(first=StrFirstOcc(def,",")) {
      len1=first-def;
      len2=StrLen(first+1);
      if(len1<len2) {
	*first=0;
      } else {
	StrCpy(def,first+1);
      }
      changed=TRUE;
    }
  }
  return StrUtil(def,SUF_REM_TRAILING|SUF_REM_LEADING);
} 
//Your on your own
U8 *GetTranslation(U8 *word,Bool recurse=TRUE) {
  I64 inst;
  U8 *str;
  if(!word) return NULL;
  U8 buf[STR_LEN],*best=NULL,buf2[STR_LEN];
  I64 idx,idx2;
  CJson *j,*t,*s0,*g,*s,*f;
  U8 *trans=NULL,*tmp;
  for(inst=0;str=GetWordString(word,,,inst);inst++) {
    j=ParseJson(str,NULL);
   if(s0=GetJsonMember(j,"senses",J_ARRAY)) {
      if(s=GetJsonMember(s0,"0",J_NODE)) { //Use first (most common ?) sense of the word
        f=GetJsonMember(s,"form_of",J_ARRAY);
        if(f) {
	  for(idx=0;t=GetJsonMember(f,StrPrint(buf,"%d",idx),J_NODE);idx++) {
	    if(t) t=GetJsonMember(t,"word",J_STR);
	    if(!t) goto defacto;
	    if(tmp=GetTranslation(t->str,FALSE)) {
	      if(!trans) trans=tmp;
	      else if(StrLen(trans)>StrLen(tmp)) {
	        Free(trans);
		trans=tmp;
	      } else
	        Free(tmp);
	    }
	  }
//Only use definition of root word
	  goto fin;
        } else {
defacto:;
	  g=GetJsonMember(s,"glosses",J_ARRAY);
//Pick shortest translation
	  if(g) {
//Use 1st (Most common?) defintion
	    if(t=GetJsonMember(g,"0",J_STR)) {
	      tmp=SmallDefinition(t->str);
	      if(!trans) trans=tmp;
	      else if(StrLen(trans)>StrLen(tmp)) {
	        Free(trans);
		trans=tmp;
	      } else
	        Free(tmp);
	    }
	  }
        }
      }
    }
fin:;
    JsonDel(j);
    Free(str);
  }
  if(!trans)
    return trans;
  return StrUtil(trans,SUF_REM_CTRL_CHARS);
}
//Returns a long list of translations
U8 *GetTranslations(U8 *word,Bool recurse=TRUE,I64 *_which=NULL) {
  I64 inst;
  U8 *str;
  if(!word) return NULL;
  U8 buf[STR_LEN],*best=NULL,buf2[STR_LEN];
  I64 idx,idx2;
  CJson *j,*t,*s0,*g,*s,*f;
  I64 which=1;
  if(!_which)
    _which=&which;
  CDoc *trans=DocNew;
  for(inst=0;str=GetWordString(word,,,inst);inst++) {
    j=ParseJson(str,NULL);
    if(s0=GetJsonMember(j,"senses",J_ARRAY)) {
      for(idx2=0;s=GetJsonMember(s0,StrPrint(buf,"%d",idx2),J_NODE);idx2++) {
        f=GetJsonMember(s,"form_of",J_ARRAY);
        if(f) {
	  for(idx=0;t=GetJsonMember(f,StrPrint(buf,"%d",idx),J_NODE);idx++) {
	    if(t) t=GetJsonMember(t,"word",J_STR);
	    if(!t) goto defacto;
	    if(best=GetTranslations(t->str,FALSE,_which)) {
	      DocPrint(trans,"%s",best);
	      Free(best);
	    }
	  }
	  goto defacto;
        } else {
defacto:
	  g=GetJsonMember(s,"glosses",J_ARRAY);
//Pick shortest translation
	  if(g) {
	    for(idx=0;t=GetJsonMember(g,StrPrint(buf,"%d",idx),J_STR);idx++) {
	      DocPrint(trans,"%d: %s\n",(*_which)++,t->str);
	    }
	  }
        }
      }
    }
    JsonDel(j);
    Free(str);
  }
  best=DocSave(trans);
  DocDel(trans);
  return StrUtil(best,SUF_REM_CTRL_CHARS);
}
CTask *p=Fs;
U0 LookUpWord(U8 *word) {
  if(FramePtr(word,trie_task))
    return;
//avoid renundant
  FramePtrAdd(word,1,trie_task);
  U8 dummy[STR_LEN];
  U8 *json_file=__DIR__"/Latin.json",*index_file=__DIR__"/INDEX.TRIE";
  U8 *str,*trans;
  I64 inst=0;
  trans=GetTranslation(word);
loop:;
  I64 flags=0,idx,idx2,base_flags=0,idx3,added=0;
  str=GetWordString(word,json_file,index_file,inst++);
  if(!str) {
    Free(trans);
    return;
  }
  CJson *j=ParseJson(str,NULL),*n,*f,*senses;
DbgPrint("%s,%s\n",word,str);
  if(n=GetJsonMember(j,"pos",J_STR)) {
    if(!StrICmp(n->str,"verb")) flags|=VERB;
    else if(!StrICmp(n->str,"noun")) flags|=NOUN;
    else if(!StrICmp(n->str,"adj")) flags|=ADJECTIVE;
    else if(!StrICmp(n->str,"conj")) flags|=CONJUNCTION;
    else if(!StrICmp(n->str,"prep")) flags|=PREPOSITION;
    else if(!StrICmp(n->str,"adv")) flags|=ADVERB;
    else if(!StrICmp(n->str,"pron")) flags|=PRONOUN;
  }
  base_flags=flags;
  for(idx3=0;idx3!=2;idx3++) {
    if(idx3==0)
      senses=GetJsonMember(j,"senses",J_ARRAY);
    else if(idx3==1)
      senses=GetJsonMember(j,"forms",J_ARRAY);
    if(senses) {
      for(idx2=0;idx2!=senses->cnt;idx2++) {
        StrPrint(dummy,"%d",idx2);
        n=GetJsonMember(senses,dummy);;
        flags=base_flags;
        if(idx3==1) {
	  if(f&&(f=GetJsonMember(n,"form",J_STR))) {
	    if(StrICmp(f->str,word))
	      goto skip;
	  } else
	    goto skip;
        }
        if(n&&(n=GetJsonMember(n,"tags",J_ARRAY))) {
	  for(idx=0;idx!=n->cnt;idx++) {
	    StrPrint(dummy,"%d",idx);
	    if(f=GetJsonMember(n,dummy,J_STR)) {
	      DbgPrint("%s for %s\n",f->str,word);
	      if(!StrICmp(f->str,"masculine")) flags|=MASCULINE;
	      if(!StrICmp(f->str,"feminine")) flags|=FEMININE;
	      if(!StrICmp(f->str,"neuter")) flags|=NEUTER;
	      if(!StrICmp(f->str,"singular")) flags|=SINGULAR;
	      if(!StrICmp(f->str,"plural")) flags|=PLURAL;
	      if(!StrICmp(f->str,"nominative")) flags|=NOMITIVE;
	      if(!StrICmp(f->str,"accusative")) flags|=ACCUSATIVE;
	      if(!StrICmp(f->str,"dative")) flags|=DATIVE;
	      if(!StrICmp(f->str,"ablative")) flags|=ABLATIVE;
	      if(!StrICmp(f->str,"genitive")) flags|=GENITIVE;
	      if(!StrICmp(f->str,"infinitive")) flags|=INFINITIVE;
	      if(!StrICmp(f->str,"imperfect")) flags|=IMPERFECT;
	      if(!StrICmp(f->str,"future")) flags|=FUTURE;
	      if(!StrICmp(f->str,"first-person")) flags|=_1P;
	      if(!StrICmp(f->str,"second-person")) flags|=_2P;
	      if(!StrICmp(f->str,"third-person")) flags|=_3P;
	      if(!StrICmp(f->str,"perfect")) flags|=PERFECT;
	      if(!StrICmp(f->str,"pluperfect")) flags|=PLUPERFECT;
	      if(!StrICmp(f->str,"subjunctive")) flags|=SUBJUNCTIVE;
	      if(!StrICmp(f->str,"passive")) flags|=PASSIVE;
	      if(!StrICmp(f->str,"comparative")) flags|=COMPARATIVE;
	      if(!StrICmp(f->str,"superlative")) flags|=SUPERLATIVE;
	      if(!StrICmp(f->str,"participle")){ flags|=PARTICIPLE;}
	      if(!StrICmp(f->str,"determiner")) flags|=DETIRMINER;
	      if(!StrICmp(f->str,"pronoun")) flags|=PRONOUN;
	      if(!StrICmp(f->str,"declension-1")) flags|=DECLENSION1;
	      if(!StrICmp(f->str,"declension-2")) flags|=DECLENSION2;
	      if(!StrICmp(f->str,"declension-3")) flags|=DECLENSION3;
	      if(!StrICmp(f->str,"declension-4")) flags|=DECLENSION4;
	      if(!StrICmp(f->str,"declension-5")) flags|=DECLENSION5;
	      if(!StrICmp(f->str,"conjugation-1")) flags|=CONJUGATION1;
	      if(!StrICmp(f->str,"conjugation-2")) flags|=CONJUGATION2;
	      if(!StrICmp(f->str,"conjugation-3")) flags|=CONJUGATION3;
	      if(!StrICmp(f->str,"conjugation-4")) flags|=CONJUGATION4;
	      if(!StrICmp(f->str,"active")) flags|=0; //ACTIVE is implicit
	      if(!StrICmp(f->str,"intransitive")) flags|=INTRANSITIVE;
	      if(!StrICmp(f->str,"superlative")) flags|=SUPERLATIVE;
	      if(!StrICmp(f->str,"comparative")) flags|=COMPARATIVE;
	      DbgPrint("%s for %s\n",f->str,word);
	    }
	  }
	  if(!TrieExists(word,flags)) {
	    added++;
	    DeclensionForWord(flags,TrieAdd(word,flags,trans));
	  }
skip:;
        }
      }
    }
  }
  if(!added)
    TrieAdd(word,base_flags,trans);
  JsonDel(j);
  Free(str);
  goto loop;
}
U32 *GetNativeWord(U8 *have) {
  U8 *raw=_GetWordString(have),*ptr;
  U8 buf[STR_LEN];
  U32 *ret=NULL,c,idx,off;
  CJson *j=ParseJson(raw,NULL),*m,*head_templates;
  "%s\n",raw;
  if(j&&(head_templates=GetJsonMember(j,"head_templates"))) {
    if(head_templates->type==J_ARRAY) {
      idx=0;
      while(TRUE) {
        StrPrint(buf,"%d",idx++);
        if(m=GetJsonMember(head_templates,buf)) {
	  if(m->type==J_NODE) {
	    m=GetJsonMember(m,"expansion");
	    if(m->type==J_STR) {
	      ret=CAlloc((StrLen(m->str)+1)*4);
	      ptr=m->str;
	      off=0;
	      while(c=ReadUTF8(ptr,&ptr)) {
		if(c==' '||c=='.')
		  break;
		if(c=='('||c=='[')
		  break;
	        ret[off++]=c;
	      }
	     goto fin;
	    }
	  }
        } else
	  break;
      } 
    }
  }
fin:;
  JsonDel(j);
  Free(raw);
  return ret;
}