#ifndef DICT_HH
#define DICT_HH 21
#include "GarabageCollector.HC";
#ifndef TrieAdd
extern U8 *TrieAdd(U8 *name, I64 flags = 0, U8 *translation = NULL);
#endif
U8 *json_file="Latin.json";
extern U8 *GetBaseWord(U8 *word,I64 inst=0);
extern U8 *GetWordString(U8 *word,I64 inst=0);
#include "Utils.HC";
CTask *mem_task=Fs;
CHashTable *word_strings=HashTableNew(1<<9);
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
  Bool used;
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
	ptr++;
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
    I32 inst_cnt;
    I64 inst_offsets[9];
    I64 inst_flags[9];
    U32 translation_idx;
    U32 body['z'-'a'+1];
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
      g->type=HTT_FRAME_PTR;
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
      g->type=HTT_FRAME_PTR;
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
  Bool first=TRUE;
  U8 num[STR_LEN];
  CHashGeneric *g;
  switch(j->type) {
    case J_STR:
      CatPrint(d,"\"%Q\"",j->str);
      break;
    case J_NUM:
      CatPrint(d,"%n",j->num);
      break;
    case J_NODE:
      CatPrint(d,"{");
      for(bucket=0;bucket<=j->hash_table->mask;bucket++)
        for(g=j->hash_table->body[bucket];g;g=g->next) {
	  if(!first) CatPrint(d,",");
	  CatPrint(d,"%s:",g->str);
	  DumpJson(d,g->user_data0);
	  first=FALSE;
        }
      CatPrint(d,"}");
      break;
    case J_ARRAY:
      CatPrint(d,"[");
      for(bucket=0;bucket<=j->hash_table->mask;bucket++)
        for(g=j->hash_table->body[bucket];g;g=g->next) {
	  if(!first) CatPrint(d,",");
	  DumpJson(d,g->user_data0);
	  first=FALSE;
        }
      CatPrint(d,"]");
  }
}
Bool TrimJson0(CJson *j,I64 argc,U8 **argv) {
  I64 i;
  I64 bucket;
  CHashGeneric *g;
  Bool ret=FALSE;
  if(j->type!=J_NODE&&j->type!=J_ARRAY) return FALSE;
  CJson *sub;
  for(bucket=0;bucket<=j->hash_table->mask;bucket++) {
again:;
    for(g=j->hash_table->body[bucket];g;g=g->next) {
      for(i=0;i!=argc;i++) {
        if(!StrCmp(g->str,argv[i])) {
	  ret=TRUE;
	  goto skip;
	}
      }
      sub=g->user_data0;
      if(sub->used) {
	goto skip;
      }
      if(!TrimJson0(sub,argc,argv)) {
        HashRemDel(g,j->hash_table);
        JsonDel(sub);
      } else {
	ret=TRUE;
	sub->used=TRUE;
      }
      goto again;
skip:;
    }
  }
  return ret;
} 
Bool TrimJson(CJson *j,...) {
  return TrimJson0(j,argc,argv);
}

U0 SubFBlkRead(CFile *file,CIndexBlk *out,I64 ptr)  {
  U8 dummies[BLK_SIZE];
  FBlkRead(file,&dummies,ptr>>1,1);
  if(ptr&1)
     MemCpy(out,&dummies[sizeof(CIndexBlk)],sizeof(CIndexBlk));
  else
     MemCpy(out,&dummies[0],sizeof(CIndexBlk));
}
U0 SubFBlkWrite(CFile *file,CIndexBlk *in,I64 ptr)  {
  U8 dummies[BLK_SIZE];
  MemSet(&dummies,0,BLK_SIZE);
  FBlkRead(file,&dummies,ptr>>1,1);
  if(ptr&1)
     MemCpy(&dummies[sizeof(CIndexBlk)],in,sizeof(CIndexBlk));
  else
     MemCpy(&dummies[0],in,sizeof(CIndexBlk));
  FBlkWrite(file,dummies,ptr>>1);
}

I64 GetWordPtr(I64 *max,CFile *file,U8*str,I64 ptr=0,Bool *new=NULL) {
  if(new) *new=FALSE;
  if(!*str) return ptr;
  I64 idx=ToUpper(*str)-'A';
  CIndexBlk dummy;
  SubFBlkRead(file,&dummy,ptr);
  if(!dummy.body[idx]) {
    dummy.body[idx]=*max;
    SubFBlkWrite(file,&dummy,ptr);
    MemSet(&dummy,0,sizeof CIndexBlk);
    SubFBlkWrite(file,&dummy,ptr=(*max)++);
    if(new) *new=TRUE;
    return GetWordPtr(max,file,str+1,ptr);
  }
  if(ptr>*max) throw('trie');
  return GetWordPtr(max,file,str+1,dummy.body[idx],new);
}
CJson *GetJsonMember(CJson *j,U8 *member,I64 type=-1) {
  CHashGeneric *g;
  if(j->type==J_ARRAY||j->type==J_NODE) {
    g=HashFind(member,j->hash_table,-1);
    if(g) {
      j=g->user_data0;
      if(type==-1) {
	return j;
      }
      else if(type==j->type) {
	return j;
      }
    }
  }
  return NULL;
}
#define INFLECT_MASK (DECLENSION1|DECLENSION2|DECLENSION3|DECLENSION4|DECLENSION5| \
	      CONJUGATION1| \
	      CONJUGATION2| \
	      CONJUGATION3| \
	      CONJUGATION4| \
	      NOUN|VERB|PARTICIPLE|INFINITIVE|PRONOUN)
#define CASE_MASK (NOMITIVE|ACCUSATIVE|ABLATIVE|DATIVE|GENITIVE|VOCATIVE)
I64 GetWordFlags0(U8 *word,CJson *j,Bool add=TRUE,U8 *trans=NULL) {
  static I64 recur=0;
  if(++recur>=2) {
    --recur;
    return 0;
  }
  I64 flags=0,base_flags=0,idx3,idx2,idx,cs,new_flags;
  U8 dummy[STR_LEN];
  Bool has_forms=FALSE;
  U8 *tmp,*wstr;
  CJson *n,*f,*senses,*formof,*tags;
  I64 inflect_mask=0;
  I64 added=0;
  if(n=GetJsonMember(j,"pos",J_STR)) {
    if(!StrICmp(n->str,"verb")) flags|=VERB;
    else if(!StrICmp(n->str,"noun")) flags|=NOUN;
    else if(!StrICmp(n->str,"adj")) flags|=ADJECTIVE;
    else if(!StrICmp(n->str,"conj")) flags|=CONJUNCTION;
    else if(!StrICmp(n->str,"prep")) flags|=PREPOSITION;
    else if(!StrICmp(n->str,"adv")) flags|=ADVERB;
    else if(!StrICmp(n->str,"pron")) flags|=PRONOUN;
    else if(!StrICmp(n->str,"det")) flags|=DETIRMINER;
  }
  base_flags=flags;
  has_forms=ToBool(GetJsonMember(j,"forms",J_ARRAY));
  for(idx3=0;idx3!=2;idx3++) {
    if(idx3==0)
      senses=GetJsonMember(j,"senses",J_ARRAY);
    else if(idx3==1) {
      senses=GetJsonMember(j,"forms",J_ARRAY);
    }
    if(senses) {
      for(idx2=0;idx2!=senses->cnt;idx2++) {
        StrPrint(dummy,"%d",idx2);
        n=GetJsonMember(senses,dummy);;
//idx3==1 is forms,make sure that the form is the same as the word
        if(idx3==1)
	  if(formof=GetJsonMember(n,"form",J_STR)) {
	    if(StrICmp(word,formof->str))
	      goto skip;
	  }// If we arent adding,just grab all the flags
        if(add) flags=base_flags;

        if(n&&(n=GetJsonMember(n,"tags",J_ARRAY))) {
	  for(idx=0;idx!=n->cnt;idx++) {
	    StrPrint(dummy,"%d",idx);
	    if(f=GetJsonMember(n,dummy,J_STR)) {
	      I64 old=flags;
	      if(!StrICmp(f->str,"masculine")) flags|=MASCULINE;
	      if(!StrICmp(f->str,"gerund")) flags|=GERUND;
	      if(!StrICmp(f->str,"feminine")) flags|=FEMININE;
	      if(!StrICmp(f->str,"neuter")) flags|=NEUTER;
	      if(!StrICmp(f->str,"singular")) flags|=SINGULAR;
	      if(!StrICmp(f->str,"plural")) flags|=PLURAL;
	      if(!StrICmp(f->str,"nominative")) flags|=NOMITIVE;
	      if(!StrICmp(f->str,"accusative")) flags|=ACCUSATIVE;
	      if(!StrICmp(f->str,"vocative")) flags|=VOCATIVE;
	      if(!StrICmp(f->str,"dative")) flags|=DATIVE;
	      if(!StrICmp(f->str,"ablative")) flags|=ABLATIVE;
	      if(!StrICmp(f->str,"genitive")) flags|=GENITIVE;
	      if(!StrICmp(f->str,"infinitive")) flags|=INFINITIVE;
	      if(!StrICmp(f->str,"imperfect")) flags|=IMPERFECT;
	      if(!StrICmp(f->str,"future")) flags|=FUTURE;
	      if(!StrICmp(f->str,"first-person")) flags|=_1P;
	      if(!StrICmp(f->str,"second-person")) flags|=_2P;
	      if(!StrICmp(f->str,"third-person")) flags|=_3P;
	      if(!StrICmp(f->str,"imperative")) flags|=IMPERATIVE;
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
	      if(!StrICmp(f->str,"present")) flags|=PRESENT;
	      DbgPrint("UNIMP:%s,%s,%x(%x)\n",f->str,word,flags|inflect_mask,old);
	    }
	  }
	  if(flags&INFINITIVE)
//Nroot doesnt like this
	    flags&=~VERB;
//Only participles got declensions
	  if(flags&(PARTICIPLE|
	        DECLENSION1|
	        DECLENSION2|
	        DECLENSION3|
	        DECLENSION4|
	        DECLENSION5
	        ))
//Nroot doesnt like this either
	    flags&=~VERB;
//Take flags  from senses.
	  if(idx3==0) {
	    if(!idx2)
	      base_flags|=flags;
	    if(has_forms)
		goto skip;
	  }
	  if(add) {
	    if(BCnt(flags&(CASE_MASK))>1) {
	      DbgPrint("CM_ADD:%d,%s,%X\n",idx3,f->str,flags);
	      static I64 each[6]={
	      NOMITIVE,
		    ACCUSATIVE,
		    ABLATIVE,
		    DATIVE,
		    GENITIVE,
		    VOCATIVE
		    };
	      for(cs=0;cs!=6;cs++) {
		new_flags=(flags&~CASE_MASK)|each[cs];
	        if(!TrieExists(word,new_flags)&&flags&each[cs]) {
		  added++;
		  DeclensionForWord(new_flags,TrieAdd(word,new_flags,trans));
	        }
	      }
	    } else
	    if(!TrieExists(word,flags)) {
	      if(flags&NOUN&&!(flags&CASE_MASK))
		goto skip;
	      DbgPrint("ADD:%d,%s,%X\n",idx3,f->str,flags);
	      added++;
	      DeclensionForWord(flags,TrieAdd(word,flags,trans));
	    }
	  }
skip:;
        }
      }
    }
  }
  --recur;
  return flags|inflect_mask;
}
U0 MakeIndex(U8 *outname,U8 *in_name) {
  CIndexBlk dummy;
  I64 len;
  U8 *optr=FileRead(in_name,&len),*fptr,*ostr;
  I64 lines,line;
  line=0,lines=StrOcc(optr,'\n');
  U8 *small=CAlloc(len);
  I64 small_ptr=0;
  Bool new;
  CFile *file;
  CHeapCtrl *oc=Fs->data_heap;
  CHashGeneric *g;
  U8 dummies[BLK_SIZE];
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
    if(j&&j->type==J_NODE) {
      g=str=GetJsonMember(j,"word");
      ostr=str->str;
      for(idx=0;ReadUTF8(ostr);idx++) {
        str->str[idx]=Transliterate(ReadUTF8(ostr,&ostr));
      }
      ostr=str->str;
      ostr[idx]=0;
      if(str&&str->type=J_STR) {
//Ensure all charactors are alpha
        for(blk=0;blk!=StrLen(str->str);blk++) {
	  if(!('A'<=ToUpper(str->str[blk])<='Z'))
	   goto skip;
        }
        blk=GetWordPtr(&sz,file,str->str,,&new);
        SubFBlkRead(file,&dummy,blk);

	if(new) {
	  dummy.inst_cnt=1;
          dummy.inst_offsets[0]=small_ptr;
//str->str is tranliterated
//	  dummy.inst_flags[0]=GetWordFlags0(str->str,j,FALSE);
	} else {
	  if(dummy.inst_cnt<9) {
	    dummy.inst_offsets[dummy.inst_cnt++]=small_ptr;
	  }
	}
	TrimJson(j,"form_of", "word","expansion","glosses","tags","pos","form");
	DumpJson(small+small_ptr,j);
	
	small_ptr+=StrLen(small_ptr+small);
        small[small_ptr++]='\n';
        SubFBlkWrite(file,&dummy,blk);
skip:;
      }
    }
    JsonDel(j);
    HeapCtrlDel(Fs->data_heap);
    Fs->data_heap=oc;
    progress1_max=lines;
    progress1=line++;
    if(line&31==0)
      Yield;
  } while(TRUE);
  ProgressBarsRst;
  file->de.size=(sz/2)<<BLK_SIZE_BITS;
  FClose(file); //Flush to disk to avoid long ram buffering
  Free(optr);
  optr=ExtChg(outname,"DEFS");
  small[small_ptr++]=0;
  FileWrite(optr,small,small_ptr);
  Free(small);
  Free(optr);
}
#include "MakeVocab.HC";

I64 GetWordOffset(U8 *word,I64 inst=0) {
  U8 buf[STR_LEN],buf2[STR_LEN];
  StrCpy(buf2,word);
  StrUtil(buf2,SUF_TO_LOWER);
  StrPrint(buf,"JsonPos.%s",buf2);
  
  I64 v=DBValue(buf,,inst+1);
  if(v==0)
    return -1;
  return v;
}

I64 GetWordDftTranslationIdx(U8 *word) {
  return 0;
}


U8 *_GetWordString(U8 *word,I64 inst=0) {
  I64 off=GetWordOffset(word,inst),off2;
  if(off==-1) return NULL;
  U8 *buffer=CAlloc(0x100000),fbuf[BLK_SIZE],*ret,*tmp;
  I64 bo=0;
  CFile *file=FOpen(json_file,"r");
  buffer[bo]=0;
loop:;
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
  //dumb hack
  tmp=SkipWhitespace(buffer);
  if(!StrOcc(tmp,'\n')) {
    goto loop;
  } else *StrFirstOcc(tmp,"\n")=0;
  FClose(file);
  tmp=StrNew(tmp);
  Free(buffer);
  return tmp;
}
U8 *GetWordString(U8 *word,I64 inst=0)  {
  U8 tnam[STR_LEN],*fr;
  StrPrint(tnam,"WS.%s,%d",word,inst);
  CHashGeneric *gen;
  I64 idx=1;
  if(fr=FramePtr(tnam,mem_task))
    return StrNew(fr);
  U8 *tmp=_GetWordString(word,inst);
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
  FramePtrAdd(tnam,StrNew(ret,mem_task),mem_task);
  return ret;
}
U8 *GetBaseWord(U8 *word,I64 inst=0) {
  U8 *ws=GetWordString(word),*p;
  if(!ws) return NULL;
  static I64 recur=0;
  if(++recur>=5) {
    --recur;
    return NULL;
  }
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
	    --recur;
	    return word;
	  }
        }
      }
      if(f=GetJsonMember(s,"glosses",J_ARRAY)) {
        if(f=GetJsonMember(f,StrPrint(buf,"%d",0),J_STR)) {
	  if(p=StrIMatch(" of ",f->str)) {
	    p+=StrLen(" of ");
	    if(StrLastOcc(p,","))
	      p=StrLastOcc(p,",")+1;
	    if(StrLastOcc(p,"."))
	      StrLastOcc(p,".")[0]=0;
	    word=StrNew(p);
	    JsonDel(j);
	    --recur;
	    return word;
	  }
        }
      }

    }
  }
  JsonDel(j);
  --recur;
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
extern U8 *GetTranslation(U8*,Bool recurse=TRUE,Bool small=FALSE,I64 inst=-1);
U8 *SmallDefinition(U8 *def) {
  if(!def) return def;
  U8 buf[STR_LEN],*bptr=buf,*want;
  Bool changed=TRUE;
  I64 len1,len2;
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
//Returns a long list of translations
U8 *GetTranslations(U8 *word,Bool recurse=TRUE,I64 *_which=NULL) {
  static I64 recur=0;
  if(++recur>=5) {
    --recur;
    return NULL;
  }
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
  for(inst=0;str=GetWordString(word,inst);inst++) {
    j=ParseJson(str,NULL);
    if(s0=GetJsonMember(j,"senses",J_ARRAY)) {
      for(idx2=0;s=GetJsonMember(s0,StrPrint(buf,"%d",idx2),J_NODE);idx2++) {
        f=GetJsonMember(s,"form_of",J_ARRAY);
        if(f) {
	  for(idx=0;t=GetJsonMember(f,StrPrint(buf,"%d",idx),J_NODE);idx++) {
	    if(t) t=GetJsonMember(t,"word",J_STR);
	    if(!t) goto defacto;
	    if(recurse)
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
	      best=SmallDefinition(t->str);
	      DocPrint(trans,"%d: %s\n",(*_which)++,best);
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
  --recur;
  return StrUtil(best,SUF_REM_CTRL_CHARS);
}
//Your on your own(inst==-1 if to use default from CIndexBlk->translation_idx)
U8 *GetTranslation(U8 *word,Bool recurse=TRUE,Bool small=TRUE,I64 t_inst=-1) {
  if(t_inst<0)
    t_inst=GetWordDftTranslationIdx(word);
  U8 *trans=GetTranslations(word,recurse),*ret;
  if(!trans) return NULL;
  I64 cnt=StrOcc(trans,'\n');
  while(ret=StrLastOcc(trans,"\n"))
    *ret=0;
  if(0<=t_inst<cnt)
    ret=StrNew(LstSub(t_inst,trans));
  else 
    ret=NULL;
  Free(trans);
  return ret;
}

CTask *p=Fs;
U0 LookUpWord(U8 *word) {
  if(FramePtr(word,trie_task))
    return;
//avoid renundant
  FramePtrAdd(word,1,trie_task);
  U8 dummy[STR_LEN];
  U8 *str,*trans;
  I64 inst=0;
  CJson *j;
  trans=GetTranslation(word);
loop:;
  I64 flags=0,idx,idx2,base_flags=0,idx3,added=0;
  str=GetWordString(word,inst);

  if(!str) {
    Free(trans);
    return;
  }
  GetWordFlags0(word,j=ParseJson(str),TRUE /* Add to trie*/ ,GetTranslation(word,TRUE));
  JsonDel(j);
  inst++;
  Free(str);
  goto loop;
}
U32 *GetNativeWord(U8 *have) {
  U8 *raw=GetWordString(have),*ptr;
  U8 buf[STR_LEN];
  U32 *ret=NULL,c,idx,off;
  CJson *j=ParseJson(raw,NULL),*m,*head_templates;
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
I64 SetWordDftTranslationIdx(U8 *word,I64 dft) {
  return 0;
}

//Use this instead of TrieGet,This will account for -ne -que suffixes
CTrie *GetWord(U8 *word) {
  if(!word) return NULL;
  if(*word=='['||*word==']')
    return NULL;
  U8 *copy=NULL;
  U8 *suffix=NULL,*prefix=NULL;
  I64 add_flags=0;
  LookUpWord(word);
  CTrie *base=TrieGet(word),*added;
  if(base) return base;
  if(!StrNICmp(word,"in",2)) {
    copy=StrNew(word+2);
    if(base=GetWord(copy)) {
      add_flags=NEGATIVE;
      prefix="in";
      goto new;
    }
    Free(copy);
  }
  if(EndsWith(word,"ne")) {
    copy=StrNew(word);
    copy[StrLen(word)-2]=0;
    LookUpWord(copy);
    if(base=TrieGet(copy)) {
      add_flags=INTEROGITIVE;
      suffix="n\e";
      goto new;
    }
    Free(copy);
  }
  if(EndsWith(word,"que")) {
    copy=StrNew(word);
    copy[StrLen(word)-3]=0;
    add_flags=CONJUNCTION2;
    suffix="que";
new:
    GetWord(copy);
    if(base=TrieGet(copy)) {
      while(base) {
        added=TrieAdd(word,base->flags|add_flags,base->translation);
	added->suffix=suffix;
	added->prefix=prefix;
	DeclensionForWord(base->flags|add_flags,added);
        base=base->next;
      }
      base=TrieGet(word);
       Free(copy);
      return base;
    }
    Free(copy);
  }
  return NULL;
}

#endif