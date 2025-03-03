#include "Trie.HC";
#include"Utils.HC";
//-ne after the first word means question
//-que means and
#defineNOMITIVE (1)
#defineGENITIVE (1<<1)
#defineDATIVE (1<<2)
#defineACCUSATIVE (1<<3)
#defineABLATIVE (1<<4)
#define SINGULAR (1<<5)
#define PLURAL(1<<6)
#define MASCULINE (1<<7)
#define FEMININE (1<<8)
#define INFINITIVE (1<<9)
#define _1P (1<<10)
#define _2P (1<<11)
#define _3P (1<<12)
#define IMPERFECT (1<<13)
#define FUTURE (1<<14)
#define CONJUNCTION (1<<15)
#define VERB (1<<16)
#define NOUN (1<<17)
#define ADJECTIVE (1<<18)
#define INFINITIVE (1<<19)
#define PRONOUN (1<<20)
#define REFLEXIVE (1<<21) //Himself
#define POSSESIVE (1<<22) //My
#define DEMONSTRATIVE (1<<23) //That
#define INTEROGITIVE (1<<24) //Who
#define NEUTER (1<<25)
#define RELATIVE (1<<26)
#define PREPOSITION (1<<27)
#define ADVERB (1<<28)
#define PERFECT (1<<29)
#define PLUPERFECT (1<<30)
#define SUBJUNCTIVE (1<<31)
//No declensions (like numbers that dont decline)
#define INDECLINABLE (1<<32)
#define PRESENT (1<<33)
#define PASSIVE (1<<34)
#define IMPERATIVE (1<<35)
#define PARTICIPLE (1<<36)
#define GERUND (1<<37)
#define COMPARATIVE (1<<38)
#define SUPERLATIVE (1<<39)
#define PARTICLE (1<<40)
#define CONJUNCTION2 (1<<41) //dixeque Words ending in -que
#define IS (1<<42) //Words like sum
#define DETIRMINER (1<<43) //things *that* are green 
#define DECLENSION1 (1<<44)
#define DECLENSION2 (1<<45)
#define DECLENSION3 (1<<46)
#define DECLENSION4 (1<<47)
#define DECLENSION5 (1<<48)
#define CONJUGATION1 (1<<49)
#define CONJUGATION2 (1<<50)
#define CONJUGATION3 (1<<51)
#define CONJUGATION4 (1<<52)
#define CONJUGATION5 (1<<53)
#define INTRANSITIVE (1<<54)
#define VOCATIVE (1<<55)
class CDeclension:CQue {
  I64 flags;
  U64 set;
  U8 *str;
};
CDeclension declensions;
CDeclension AddDeclension(U8*declen,I64 flags,U64 set){
  CDeclension *d=CAlloc(sizeofCDeclension);
  U8 as_str[9];
  as_str[0](U64)=set;
  as_str[8]=0;
  if(as_str[1]=='v') {
    if(set.u8[0]=='1')
      flags|=CONJUGATION1; 
    if(set.u8[0]=='2')
      flags|=CONJUGATION2;
    if(set.u8[0]=='3')
      flags|=CONJUGATION3;
    if(set.u8[0]=='4')
      flags|=CONJUGATION4;
  } else if(as_str[0]=='d') {
    if(set.u8[1]=='1')
      flags|=DECLENSION1;
    if(set.u8[1]=='2')
      flags|=DECLENSION2;
    if(set.u8[1]=='3')
      flags|=DECLENSION3;
    if(set.u8[1]=='4')
      flags|=DECLENSION4;
    if(set.u8[1]=='5')
      flags|=DECLENSION5;
  }
  d->flags=flags;
  d->set=set;
  d->str=StrNew(declen);
  QueIns(d,&declensions);
  return d;
}
Bool EndsWith(U8 *a,U8 *with) {
  if(StrLen(with)>StrLen(a)) return FALSE;
  return !StrCmp(with,a+StrLen(a)-StrLen(with));
}

Bool IsOfDelcensionSet(U8 *str,U64 set,I64 flags) {
  CDeclension *d,*head=&declensions;
  for(d=head->next;head!=d;d=d->next)
    if(d->set==set&&d->flags&flags==flags)
      if(EndsWith(str,d->str)&&StrLen(d->str)) //Empty endings are speacial
        return TRUE;
  return FALSE;
}

I64 GetTrimLength(U8 *str,U64 set,I64 flags=0,I64 anti_flags=0) {
  CDeclension *d,*head=&declensions;
  I64 t=0;
  for(d=head->next;head!=d;d=d->next) {
    if(d->set==set&&d->flags&flags==flags&&!(d->flags&anti_flags)) {
      if(EndsWith(str,d->str))
	t=MaxI64(StrLen(d->str),t);
    }
  }
  return t;
}
CFifoI64 *DelcensionsForFlags(I64 flags,U64 set) {
  CFifoI64 *ret=FifoI64New(0x20);
  CDeclension *d,*head=&declensions;
  for(d=head->next;head!=d;d=d->next)
    if(d->set==set&&d->flags&flags==flags)
      FifoI64Ins(ret,d);
  return ret;
}

U0 PrintDelcensForFlags(U8 *base,I64 flags,U64 set) {
  CFifoI64 *declens=DelcensionsForFlags(flags,set);
  CDeclension *d;
  Bool first=TRUE;
  while(FifoI64Rem(declens,&d)) {
    if(!first) "/";
    first=FALSE;
  }
  FifoI64Del(declens);
}

Bool MatchesFlags(I64 a,I64 b) {
  I64 mask=DECLENSION1|DECLENSION2|DECLENSION3|DECLENSION4|DECLENSION5|
        CONJUGATION1|
        CONJUGATION2|
        CONJUGATION3|
        CONJUGATION4;
  if(b&mask) //Maybe we dont know the inflection
    if(!(a&b&mask))
      return FALSE;
//Gender
  mask=MASCULINE|FEMININE|NEUTER;
  if(a&mask&&b&mask) {
    if(!(a&mask&b))
      return FALSE;
  }
  if(a&(VERB|INFINITIVE)) {
    if(!(b&(VERB|INFINITIVE))) return FALSE;
//Passive/Active
    if(a&PASSIVE!=b&PASSIVE) 
      return FALSE;
//Person
    mask=_1P|_2P|_3P;
    if(a&mask!=b&mask) 
      return FALSE;
//Mood
    mask=IMPERATIVE|SUBJUNCTIVE;
    if(a&mask!=b&mask) 
      return FALSE;
//Tense
    mask=FUTURE|PLUPERFECT|PERFECT|IMPERFECT|PRESENT;
    if(a&mask!=b&mask) 
      return FALSE;
    mask=SINGULAR|PLURAL;
    if(a&mask&&b&mask) {
      if(!(a&mask&b))
        return FALSE;
    }
    return TRUE;
  }
//Number
  mask=SINGULAR|PLURAL;
  if(a&mask)
    if(a&mask&&b&mask) {
      if(!(a&mask&b))
        return FALSE;
    }
//Case
  mask=GENITIVE|DATIVE|ABLATIVE|NOMITIVE|ACCUSATIVE|VOCATIVE;
  if(a&mask)
    if(!(a&mask&b)) 
      return FALSE;
  return TRUE;
}

CDeclension *DeclensionForWord(I64 flags,CTrie *w) {
  I64 max_l=0,l;
  CDeclension *d,*head=&declensions,*d2;
  for(d=head->next;d!=head;d=d->next) {
    if(EndsWith(w->str,d->str)) {
      if(MatchesFlags(d->flags,w->flags)) {
        l=StrLen(d->str);
        max_l=MaxI64(l,max_l);
	if(max_l==l)
	  w->front_declension=d->str;
      }
    }
  }
  return w->front_declension;
}


U0 InitLatin(U8 *file="Latin.INFLECTS") {
  QueInit(&declensions);
  if(!FileFind(file))
    return ;
  I64 line;
  U8 *txt,*otxt=FileRead(file),*tmp;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 flags_str[STR_LEN],*flags_ptr=flags_str;
  U8 ending[STR_LEN],*end_ptr=ending; 
  U8 trans[STR_LEN];
  I64 flags,c,cnt,idx;
  txt=otxt;
  while(txt=StrFirstOcc(txt,"\n")) {
    *txt=0;
    txt++;
  }
  for(line=0;txt=LstSub(line,otxt);line++) {
    if(StrOcc(txt,'\t')>=2) {
      StrScan(txt,"\"%s\"\t%s\t\"%s\"",&cls_ptr,&flags_ptr,&end_ptr);
      if(ending[0]=='-')
        StrCpy(ending,"");
      flags=ExePrint2("%s;\n",flags_str);
      trans[0]=0;
      cnt=1;
      while(tmp=StrLastOcc(ending,"/"))
        ++cnt,*tmp=0;
      for(idx=0;idx!=cnt;idx++) {
        tmp=LstSub(idx,ending);
        if(tmp) {
	  while(c=ReadUTF8(tmp,&tmp)) {
	    CatPrint(trans,"%c",Transliterate(c));
	  }
	  AddDeclension(trans,flags,cls[0](U64));
        }
      }
    }
  }
  Free(otxt);
}
InitLatin;
#include "Dict.HC";
//Use this instead of TrieGet,This will account for -ne -que suffixes
CTrie *GetWord(U8 *word) {
  if(!word) return NULL;
  if(*word=='['||*word==']')
    return NULL;
  U8 *copy=NULL;
  LookUpWord(word);
  CTrie *base=TrieGet(word);
  if(base) return base;
  if(EndsWith(word,"ne")) {
    copy=StrNew(word);
    copy[StrLen(word)-2]=0;
    if(base=TrieGet(copy)) {
      Free(copy);
      return TrieAdd(word,base->flags|INTEROGITIVE);
    }
    Free(copy);
  }
  if(EndsWith(word,"que")) {
    copy=StrNew(word);
    copy[StrLen(word)-3]=0;
    if(base=TrieGet(copy)) {
      Free(copy);
      return TrieAdd(word,base->flags|CONJUNCTION2|CONJUNCTION,base->translation);
    }
    Free(copy);
  }
//  DbgPrint("Unknonw word %s\n",word);
  return NULL;
}
