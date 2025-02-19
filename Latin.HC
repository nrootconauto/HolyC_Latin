#include "Trie.HC";
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
class CDeclension:CQue {
  I64 flags;
  U64 set;
  U8 *str;
};
CDeclension declensions;
CDeclension AddDeclension(U8*declen,I64 flags,U64 set){
  CDeclension *d=CAlloc(sizeofCDeclension);
  if(flags&VERB) {
    if(set.u8[0]=='1')
      flags|=CONJUGATION1; 
    if(set.u8[0]=='2')
      flags|=CONJUGATION2;
    if(set.u8[0]=='3')
      flags|=CONJUGATION3;
    if(set.u8[0]=='4')
      flags|=CONJUGATION4;
  } else {
    if(set.u8[0]=='1')
      flags|=DECLENSION1;
    if(set.u8[0]=='2')
      flags|=DECLENSION2;
    if(set.u8[0]=='3')
      flags|=DECLENSION3;
    if(set.u8[0]=='4')
      flags|=DECLENSION4;
    if(set.u8[0]=='5')
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

//Consult your local Latin dictionary for this one
U0 _AddWordByPrincibleParts(U8 *translation=NULL,I64 add_flags,I64 flags,I64 argc,U8 **argv) {
  CDeclension *d=declensions.next,*head=&declensions,*d2;
  U64 valid_classes[0x80];
  U8 *base,*word,*word2;
  I64 i,part,valid_cls_cnt=0,i2,trim;
  U8 *dummy_argv[2];
  for(d=head->next;d!=head;d=d->next) {
    if(!StrLen(d->str)) {
      part=0;
      goto check;
    } else if(d->set=='2v'
	  ||d->set=='1v'
	  ||d->set=='3v'
	  ||d->set='3iov'
	  ||d->set=='4v'
    ) {
      if(d->flags&(PERFECT|PLUPERFECT))
        part=2;
      else if(d->flags&(_1P|SINGULAR)==(_1P|SINGULAR))
        part=0;
      else
        part=1;
      goto check;
    } else if(d->set=='adj12'
	  ||d->set=='adj3'
	  ||d->set=='1d'
	  ||d->set=='2n'
	  ||d->set=='2mfd'
	  ||d->set=='3nd'
	  ||d->set=='3mfd'
	  ||d->set=='4mfd'
	  ||d->set=='4nd'
	  ||d->set=='5mfd'
    ) {
      if(d->flags&(NOMITIVE|SINGULAR)==(NOMITIVE|SINGULAR))
        part=0;
      else
        part=1;
      goto check;
    } else {
      part=0;
check:
      if(part<argc)
        if(EndsWith(argv[part],d->str)&&(d->flags&flags==flags)) {
	  for(i2=0;i2!=valid_cls_cnt;i2++) {
	    if(valid_classes[i2]==d->set)
	      goto pass;
	  }
//Check that all endings are in the delcension(except for first one as it may be special)
	  for(i2=1;i2<argc;i2++)
	    if(!IsOfDelcensionSet(argv[i2],d->set,flags))
	      goto pass;
	  valid_classes[valid_cls_cnt++]=d->set;
pass:;
        }
    }
  }
  for(d=head->next;d!=head;d=d->next) {
    for(i2=0;i2!=valid_cls_cnt;i2++) {
      if(valid_classes[i2]==d->set) {
        if(!StrLen(d->str)) {
	  trim=0;
	  part=0;
        } else if(d->set=='2v'
	      ||d->set=='1v'
	      ||d->set=='3v'
	      ||d->set=='3iov'
	      ||d->set=='4v') {
	  if(d->flags&(PERFECT|PLUPERFECT)) {
	    part=2;
	    if(part<argc)
	      trim=MaxI64(
		    GetTrimLength(argv[part],valid_classes[i2],PERFECT),
		    GetTrimLength(argv[part],valid_classes[i2],PLUPERFECT)
	      );
	  } else if(d->flags&(_1P|SINGULAR)==(_1P|SINGULAR)) {
	    part=0;
	    if(part<argc)
	      trim=GetTrimLength(argv[part],valid_classes[i2],_1P|SINGULAR,PERFECT|PLUPERFECT);
	  } else {
	    part=1;
	    if(part<argc)
	      trim=GetTrimLength(argv[part],valid_classes[i2],,PERFECT|PLUPERFECT);
	  }
        } else if(d->set=='adj12'||d->set=='adj3'
	      ||d->set=='adj3'
	      ||d->set=='1d'
	      ||d->set=='2n'
	      ||d->set=='2mfd'
	      ||d->set=='3nd'
	      ||d->set=='3mfd'
	      ||d->set=='4mfd'
	      ||d->set=='4nd'
	      ||d->set=='5mfd') {
	  if(d->flags&(NOMITIVE|SINGULAR)==(NOMITIVE|SINGULAR))
	    trim=part=0;
	  else {
	    part=1;
	    trim=GetTrimLength(argv[part],valid_classes[i2]);
	  }
        } else {
	  part=0;
	  trim=GetTrimLength(argv[part],valid_classes[i2]);
        }
        if(part<argc) {
	  base=StrNew(argv[part]);
	  base[StrLen(base)-trim]=0;
	  word=MStrPrint("%s%s",base,d->str);
	  TrieAdd(word,d->flags|add_flags,translation)->front_declension=StrNew(d->str);
	  Free(base),Free(word);
        }

      }
    }
  }
  for(i2=0;i2!=valid_cls_cnt;i2++) {
//Handle participles here,they act like adjectives
    if(valid_classes[i2]=='1v'&&2<argc) {
      part=2;
      base=StrNew(argv[part]);
      trim=GetTrimLength(argv[part],valid_classes[i2]);
      base[StrLen(base)-trim]=0;
      word=MStrPrint("%sans",base);
      word2=MStrPrint("%santis",base);
//Participles are like adjectives
      dummy_argv[0]=word,dummy_argv[1]=word2;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,2,dummy_argv);
      Free(word);
      word=MStrPrint("%surus",base);
      dummy_argv[0]=word;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,1,dummy_argv);
      Free(base),Free(word),Free(word2);
    }
    if((valid_classes[i2]=='2v'||valid_classes[i2]=='3v'||valid_classes[i2]=='4v')&&2<argc) {
      part=2;
      base=StrNew(argv[part]);
      trim=GetTrimLength(argv[part],valid_classes[i2]);
      base[StrLen(base)-trim]=0;
      word=MStrPrint("%sens",base);
      word2=MStrPrint("%sentis",base);
      dummy_argv[0]=word,dummy_argv[1]=word2;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,2,dummy_argv);
      Free(word);
      word=MStrPrint("%surus",base);
      dummy_argv[0]=word;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,1,dummy_argv);
      Free(base),Free(word),Free(word2);

    }
    if(valid_classes[i2]=='3iov'&&2<argc) {
      part=2;
      base=StrNew(argv[part]);
      trim=GetTrimLength(argv[part],valid_classes[i2]);
      base[StrLen(base)-trim]=0;
      word=MStrPrint("%isens",base);
      word2=MStrPrint("%sientis",base);
      dummy_argv[0]=word,dummy_argv[1]=word2;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,2,dummy_argv);
      Free(word);
      word=MStrPrint("%surus",base);
      dummy_argv[0]=word;
      _AddWordByPrincibleParts(translation,PARTICIPLE,ADJECTIVE,1,dummy_argv);
      Free(base),Free(word),Free(word2);
    }
    if(!(add_flags&(COMPARATIVE|SUPERLATIVE))) {
      if(valid_classes[i2]=='adj12'||valid_classes[i2]=='adj3') {
//Adjectives comparative
        if(1<argc) {
	  part=1;
	  base=StrNew(argv[part]);
	  trim=GetTrimLength(argv[part],valid_classes[i2]);
	  base[StrLen(base)-trim]=0;
	  word=MStrPrint("%sior",base);
	  word2=MStrPrint("%sioris",base);
	  dummy_argv[0]=word,dummy_argv[1]=word2;
	  _AddWordByPrincibleParts(translation,COMPARATIVE,ADJECTIVE,2,dummy_argv);
	  Free(base),Free(word),Free(word2);
        }
//http://www.thelatinlibrary.com/101/AdjComp.pdf
        //Superlative
        if(1<argc&&EndsWith(argv[0],"er")) {
	  part=1;
	  base=StrNew(argv[part]);
	  trim=2;
	  base[StrLen(base)-trim]=0;
	  word=MStrPrint("%srimus",base);
	  word2=MStrPrint("%srima",base); 
	  dummy_argv[0]=word,dummy_argv[1]=word2;
	  _AddWordByPrincibleParts(translation,SUPERLATIVE,ADJECTIVE,2,dummy_argv);
	  Free(base),Free(word),Free(word2);
        } else if(1<argc&&EndsWith(argv[0],"ilis")) {
	  part=1;
	  base=StrNew(argv[part]);
	  trim=4;
	  base[StrLen(base)-trim]=0;
	  word=MStrPrint("%slimus",base);
	  word2=MStrPrint("%slima",base); 
	  dummy_argv[0]=word,dummy_argv[1]=word2;
	  _AddWordByPrincibleParts(translation,SUPERLATIVE,ADJECTIVE,2,dummy_argv);
	  Free(base),Free(word),Free(word2);
        } else {
	  part=1;
	  base=StrNew(argv[part]);
	  trim=GetTrimLength(argv[part],valid_classes[i2]);
	  base[StrLen(base)-trim]=0;
	  word=MStrPrint("%ssimus",base);
	  word2=MStrPrint("%ssimma",base);
	  dummy_argv[0]=word,dummy_argv[1]=word2;
	  _AddWordByPrincibleParts(translation,SUPERLATIVE,ADJECTIVE,2,dummy_argv);
	  Free(base),Free(word),Free(word2);
        }
      }
    }
  }
}

U0 AddWordByPrincibleParts(U8*translation=NULL,I64 flags,...) {
  _AddWordByPrincibleParts(translation,0,flags,argc,argv);
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
    "%s%s",base,d->str;
    first=FALSE;
  }
  FifoI64Del(declens);
}
CDeclension *DeclensionForWord(I64 flags,CTrie *w) {
  I64 mask=DECLENSION1|DECLENSION2|DECLENSION3|DECLENSION4|DECLENSION5|
	NOUN|VERB|ADJECTIVE|CONJUGATION1|
	CONJUGATION2|
	CONJUGATION3|
	CONJUGATION4;
  CDeclension *d,*head=&declensions,*d2;
  for(d=head->next;d!=head;d=d->next) {
    if(EndsWith(w->str,d->str)) {
      if(mask&d->flags) {
	w->front_declension=d->str;
	return d;
      }
    }
  }
  return NULL;
}


U0 InitLatin() {
  QueInit(&declensions);
  I64 iter=0,cls;
//1St Delcnesion 
  AddDeclension("a",SINGULAR|NOMITIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("ae",PLURAL|NEUTER|MASCULINE|FEMININE|NOUN|NOMITIVE,'1d');
  AddDeclension("ae",SINGULAR|GENITIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("arum",PLURAL|GENITIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("ae",SINGULAR|DATIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("is",PLURAL|DATIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("am",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("as",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("a",SINGULAR|ABLATIVE|MASCULINE|FEMININE|NOUN,'1d');
  AddDeclension("is",PLURAL|ABLATIVE|MASCULINE|FEMININE|NOUN,'1d');
//2nd declennsion M/F us
  AddDeclension("",SINGULAR|NOMITIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("us",SINGULAR|NOMITIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("i",PLURAL|NOMITIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("i",SINGULAR|GENITIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("orum",PLURAL|GENITIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("o",SINGULAR|DATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("is",PLURAL|DATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("um",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("os",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("o",SINGULAR|ABLATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
  AddDeclension("is",PLURAL|ABLATIVE|MASCULINE|FEMININE|NOUN,'2mfd');
//2nd declennsion N
  AddDeclension("",SINGULAR|NOMITIVE|NEUTER|NOUN,'2mfd');
  AddDeclension("er",SINGULAR|NOMITIVE|NEUTER|NOUN,'2nd');
  AddDeclension("i",PLURAL|NOMITIVE|NEUTER|NOUN,'2nd');
  AddDeclension("i",SINGULAR|GENITIVE|NEUTER|NOUN,'2nd');
  AddDeclension("orum",PLURAL|GENITIVE|NEUTER|NOUN,'2nd');
  AddDeclension("o",SINGULAR|DATIVE|NEUTER|NOUN,'2nd');
  AddDeclension("is",PLURAL|DATIVE|NEUTER|NOUN,'2nd');
  AddDeclension("um",SINGULAR|ACCUSATIVE|NEUTER|NOUN,'2nd');
  AddDeclension("os",PLURAL|ACCUSATIVE|NEUTER|NOUN,'2nd');
  AddDeclension("o",SINGULAR|ABLATIVE|NEUTER|NOUN,'2nd');
  AddDeclension("is",PLURAL|ABLATIVE|NEUTER|NOUN,'2nd');
//3rd declension nouns M
  AddDeclension("",SINGULAR|NOMITIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("es",PLURAL|NOMITIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("is",SINGULAR|GENITIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("um",PLURAL|GENITIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("i",SINGULAR|DATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("ibus",PLURAL|DATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("em",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("es",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("e",SINGULAR|ABLATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
  AddDeclension("ibus",PLURAL|ABLATIVE|MASCULINE|FEMININE|NOUN,'3mfd');
//3rd declension Neuter
  AddDeclension("",SINGULAR|NOMITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("a",PLURAL|NOMITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("ia",PLURAL|NOMITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("is",SINGULAR|GENITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("um",PLURAL|GENITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("ium",PLURAL|GENITIVE|NEUTER|NOUN,'3nd');
  AddDeclension("i",SINGULAR|DATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("ibus",PLURAL|DATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("",SINGULAR|ACCUSATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("a",PLURAL|ACCUSATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("ia",PLURAL|ACCUSATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("e",SINGULAR|ABLATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("i",SINGULAR|ABLATIVE|NEUTER|NOUN,'3nd');
  AddDeclension("ibus",PLURAL|ABLATIVE|NEUTER|NOUN,'3nd');
//4th declension M/F
  AddDeclension("",SINGULAR|NOMITIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("us",PLURAL|NOMITIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("us",SINGULAR|GENITIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("uum",PLURAL|GENITIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("ui",SINGULAR|DATIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("ibus",PLURAL|DATIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("um",SINGULAR|ACCUSATIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("us",PLURAL|ACCUSATIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("u",SINGULAR|ABLATIVE|NEUTER|NOUN,'4mfd');
  AddDeclension("ibus",PLURAL|ABLATIVE|NEUTER|NOUN,'4mfd');
//4th declension N
  AddDeclension("",SINGULAR|NOMITIVE|NEUTER|NOUN,'4n');
  AddDeclension("ua",PLURAL|NOMITIVE|NEUTER|NOUN,'4nd');
  AddDeclension("u",SINGULAR|GENITIVE|NEUTER|NOUN,'4nd');
  AddDeclension("uum",PLURAL|GENITIVE|NEUTER|NOUN,'4nd');
  AddDeclension("u",SINGULAR|DATIVE|NEUTER|NOUN,'4nd');
  AddDeclension("ibus",PLURAL|DATIVE|NEUTER|NOUN,'4nd');
  AddDeclension("u",SINGULAR|ACCUSATIVE|NEUTER|NOUN,'4nd');
  AddDeclension("ua",PLURAL|ACCUSATIVE|NEUTER|NOUN,'4nd');
  AddDeclension("u",SINGULAR|ABLATIVE|NEUTER|NOUN,'4nd');
  AddDeclension("ibus",PLURAL|ABLATIVE|NEUTER|NOUN,'4nd');
//%th declension MF
  AddDeclension("",SINGULAR|NOMITIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("es",PLURAL|NOMITIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("ei",SINGULAR|GENITIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("erum",PLURAL|GENITIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("ei",SINGULAR|DATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("ebus",PLURAL|DATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("em",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("es",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("e",SINGULAR|ABLATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
  AddDeclension("ebus",PLURAL|ABLATIVE|MASCULINE|FEMININE|NOUN,'5mfd');
//3rd declennsion MF Adjective
  AddDeclension("",SINGULAR|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",SINGULAR|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("es",PLURAL|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",SINGULAR|GENITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ium",PLURAL|GENITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|DATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|DATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("em",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("es",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibu",PLURAL|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
//3nd DEclensiuonb N0 Adjective
  AddDeclension("",SINGULAR|NOMITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("a",PLURAL|NOMITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("ia",PLURAL|NOMITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("is",SINGULAR|GENITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("um",PLURAL|GENITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("ium",PLURAL|GENITIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|DATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|DATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("",SINGULAR|ACCUSATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("a",PLURAL|ACCUSATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("ia",PLURAL|ACCUSATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("",SINGULAR|ABLATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|ABLATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("a",PLURAL|ABLATIVE|NEUTER|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|ABLATIVE|NEUTER|ADJECTIVE,'adj3');
//3rd Declension 2Endings
  AddDeclension("",SINGULAR|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",SINGULAR|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("es",PLURAL|NOMITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",SINGULAR|GENITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ium",PLURAL|GENITIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|DATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|DATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("em",SINGULAR|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("es",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("is",PLURAL|ACCUSATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("i",SINGULAR|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibu",PLURAL|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');
  AddDeclension("ibus",PLURAL|ABLATIVE|MASCULINE|FEMININE|ADJECTIVE,'adj3');



  //TODO future infinitive
  //1st conjuation present tense
  AddDeclension("o",SINGULAR|_1P|VERB|PRESENT,'1v');
  AddDeclension("amus",PLURAL|_1P|VERB|PRESENT,'1v');
  AddDeclension("as",SINGULAR|_2P|VERB|PRESENT,'1v');
  AddDeclension("atis",PLURAL|_2P|VERB|PRESENT,'1v');
  AddDeclension("at",SINGULAR|_3P|VERB|PRESENT,'1v');
  AddDeclension("ant",PLURAL|_3P|VERB|PRESENT,'1v');
//1st conjugation passive
  AddDeclension("or",SINGULAR|_1P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("amur",PLURAL|_1P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("aris",SINGULAR|_2P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("are",SINGULAR|_2P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("amini",PLURAL|_2P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("atur",SINGULAR|_3P|VERB|PRESENT|PASSIVE,'1v');
  AddDeclension("antur",PLURAL|_3P|VERB|PRESENT|PASSIVE,'1v');
//Impefect tense 1st conujation
  AddDeclension("abam",SINGULAR|_1P|IMPERFECT|VERB,'1v');
  AddDeclension("abamus",PLURAL|_1P|IMPERFECT|VERB,'1v');
  AddDeclension("abas",SINGULAR|_2P|IMPERFECT|VERB,'1v');
  AddDeclension("abatis",PLURAL|_2P|IMPERFECT|VERB,'1v');
  AddDeclension("abat",SINGULAR|_3P|IMPERFECT|VERB,'1v');
  AddDeclension("abant",PLURAL|_3P|IMPERFECT|VERB,'1v');
//Impefect tense 1st conujation passive
  AddDeclension("abar",SINGULAR|_1P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abamur",PLURAL|_1P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abaris",SINGULAR|_2P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abare",SINGULAR|_2P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abamini",PLURAL|_2P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abatur",SINGULAR|_3P|IMPERFECT|VERB|PASSIVE,'1v');
  AddDeclension("abantur",PLURAL|_3P|IMPERFECT|VERB|PASSIVE,'1v');
//1st conjuation PERFECT  tense
  AddDeclension("avi",SINGULAR|_1P|PERFECT|VERB,'1v');
  AddDeclension("avimus",PLURAL|_1P|PERFECT|VERB,'1v');
  AddDeclension("avisti",SINGULAR|_2P|PERFECT|VERB,'1v');
  AddDeclension("avistis",PLURAL|_2P|PERFECT|VERB,'1v');
  AddDeclension("avit",SINGULAR|_3P|PERFECT|VERB,'1v');
  AddDeclension("averunt",PLURAL|_3P|PERFECT|VERB,'1v');
  AddDeclension("avere",PLURAL|_3P|PERFECT|VERB,'1v');
//1st conjuation FUTURE tense
  AddDeclension("abo",SINGULAR|_1P|FUTURE|VERB,'1v');
  AddDeclension("abimus",PLURAL|_1P|FUTURE|VERB,'1v');
  AddDeclension("abis",SINGULAR|_2P|FUTURE|VERB,'1v');
  AddDeclension("abitis",PLURAL|_2P|FUTURE|VERB,'1v');
  AddDeclension("abis",SINGULAR|_3P|FUTURE|VERB,'1v');
  AddDeclension("abit",PLURAL|_3P|FUTURE|VERB,'1v');
  AddDeclension("abunt",PLURAL|_3P|FUTURE|VERB,'1v');
//1st PLUPERFECT
  AddDeclension("averam",PLUPERFECT|SINGULAR|_1P|VERB,'1v');
  AddDeclension("averamus",PLUPERFECT|PLURAL|_1P|VERB,'1v');
  AddDeclension("averas",PLUPERFECT|SINGULAR|_2P|VERB,'1v');
  AddDeclension("averatis",PLUPERFECT|PLURAL|_2P|VERB,'1v');
  AddDeclension("averat",PLUPERFECT|SINGULAR|_3P|VERB,'1v');
  AddDeclension("averant",PLUPERFECT|PLURAL|_3P|VERB,'1v');
//1st Present subjunctive
  AddDeclension("em",SUBJUNCTIVE|_1P|SINGULAR|VERB,'1v');
  AddDeclension("emus",SUBJUNCTIVE|_1P|PLURAL|VERB,'1v');
  AddDeclension("es",SUBJUNCTIVE|_2P|SINGULAR|VERB,'1v');
  AddDeclension("etis",SUBJUNCTIVE|_2P|PLURAL|VERB,'1v');
  AddDeclension("et",SUBJUNCTIVE|_3P|SINGULAR|VERB,'1v');
  AddDeclension("ent",SUBJUNCTIVE|_3P|PLURAL|VERB,'1v');
//1st Present subjunctive passive
  AddDeclension("er",SUBJUNCTIVE|_1P|SINGULAR|VERB|PASSIVE,'1v');
  AddDeclension("emur",SUBJUNCTIVE|_1P|PLURAL|VERB|PASSIVE,'1v');
  AddDeclension("eris",SUBJUNCTIVE|_2P|SINGULAR|VERB|PASSIVE,'1v');
  AddDeclension("ere",SUBJUNCTIVE|_2P|SINGULAR|VERB|PASSIVE,'1v');
  AddDeclension("emini",SUBJUNCTIVE|_2P|PLURAL|VERB|PASSIVE,'1v');
  AddDeclension("etur",SUBJUNCTIVE|_3P|SINGULAR|VERB|PASSIVE,'1v');
  AddDeclension("entur",SUBJUNCTIVE|_3P|PLURAL|VERB|PASSIVE,'1v');
//1st Present subjunctive IMPERFECT
  AddDeclension("arem",SUBJUNCTIVE|_1P|SINGULAR|VERB|IMPERFECT,'1v');
  AddDeclension("aremus",SUBJUNCTIVE|_1P|PLURAL|VERB|IMPERFECT,'1v');
  AddDeclension("ares",SUBJUNCTIVE|_2P|SINGULAR|VERB|IMPERFECT,'1v');
  AddDeclension("aretis",SUBJUNCTIVE|_2P|PLURAL|VERB|IMPERFECT,'1v');
  AddDeclension("aret",SUBJUNCTIVE|_3P|SINGULAR|VERB|IMPERFECT,'1v');
  AddDeclension("arent",SUBJUNCTIVE|_3P|PLURAL|VERB|IMPERFECT,'1v');
//1st Present subjunctive passive IMPERFECT
  AddDeclension("arer",SUBJUNCTIVE|_1P|SINGULAR|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("aremur",SUBJUNCTIVE|_1P|PLURAL|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("areris",SUBJUNCTIVE|_2P|SINGULAR|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("arere",SUBJUNCTIVE|_2P|SINGULAR|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("aremini",SUBJUNCTIVE|_2P|PLURAL|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("aretur",SUBJUNCTIVE|_3P|SINGULAR|VERB|PASSIVE|IMPERFECT,'1v');
  AddDeclension("arentur",SUBJUNCTIVE|_3P|PLURAL|VERB|PASSIVE|IMPERFECT,'1v');
//1st Present subjunctive PERFECT
  AddDeclension("averem",SUBJUNCTIVE|_1P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("averemus",SUBJUNCTIVE|_1P|PLURAL|VERB|PERFECT,'1v');
  AddDeclension("averes",SUBJUNCTIVE|_2P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("averetis",SUBJUNCTIVE|_2P|PLURAL|VERB|PERFECT,'1v');
  AddDeclension("averet",SUBJUNCTIVE|_3P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("averent",SUBJUNCTIVE|_3P|PLURAL|VERB|PERFECT,'1v');
//1st Present subjunctive PLUPERFECT
  AddDeclension("avissem",SUBJUNCTIVE|_1P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("avissemus",SUBJUNCTIVE|_1P|PLURAL|VERB|PERFECT,'1v');
  AddDeclension("avisses",SUBJUNCTIVE|_2P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("avissetis",SUBJUNCTIVE|_2P|PLURAL|VERB|PERFECT,'1v');
  AddDeclension("avisset",SUBJUNCTIVE|_3P|SINGULAR|VERB|PERFECT,'1v');
  AddDeclension("avissent",SUBJUNCTIVE|_3P|PLURAL|VERB|PERFECT,'1v');
//1st PRESENT IMPERATIVE ACTIVE
  AddDeclension("a",IMPERATIVE|_2P|SINGULAR|VERB,'1v');
  AddDeclension("ate",IMPERATIVE|_2P|PLURAL|VERB,'1v');
//1st  FUTURE IMPERATIVE ACTIVE
  AddDeclension("ato",IMPERATIVE|_2P|SINGULAR|VERB|FUTURE,'1v');
  AddDeclension("ato",IMPERATIVE|_3P|PLURAL|VERB|FUTURE,'1v');
  AddDeclension("atote",IMPERATIVE|_2P|SINGULAR|VERB|FUTURE,'1v');
  AddDeclension("anto",IMPERATIVE|_3P|PLURAL|VERB|FUTURE,'1v');
//1st PRESENT IMPERATIVE PASSIVE
  AddDeclension("are",IMPERATIVE|_2P|SINGULAR|VERB,'1v');
  AddDeclension("amini",IMPERATIVE|_2P|PLURAL|VERB,'1v');
//1st  FUTURE IMPERATIVE PASSIVE
  AddDeclension("ator",IMPERATIVE|_2P|SINGULAR|VERB|FUTURE,'1v');
  AddDeclension("ator",IMPERATIVE|_3P|PLURAL|VERB|FUTURE,'1v');
  AddDeclension("antor",IMPERATIVE|_3P|PLURAL|VERB|FUTURE,'1v');
//1st INFINTIVE
  AddDeclension("are",INFINITIVE,'1v');
  AddDeclension("visse",INFINITIVE|FUTURE,'1v');
  AddDeclension("ari",INFINITIVE|SUBJUNCTIVE,'1v');
//This is handled by AddWordByPrincibleParts
/*//1st PARTICIPLE 
  AddDeclension("ans",PARTICIPLE,'1v');
  AddDeclension("antis",PARTICIPLE,'1v');
  AddDeclension("aturus",PARTICIPLE|FUTURE,'1v');*/
//1st GERUND
  AddDeclension("andi",GERUND|GENITIVE,'1v');
  AddDeclension("ando",GERUND|DATIVE,'1v');
   AddDeclension("andum",GERUND|ACCUSATIVE,'1v');
  AddDeclension("ando",GERUND|ABLATIVE,'1v');

  //2nd conjuation present tense
  AddDeclension("eo",SINGULAR|_1P|VERB|PRESENT,'2v');
  AddDeclension("emus",PLURAL|_1P|VERB|PRESENT,'2v');
  AddDeclension("es",SINGULAR|_2P|VERB|PRESENT,'2v');
  AddDeclension("etis",PLURAL|_2P|VERB|PRESENT,'2v');
  AddDeclension("et",SINGULAR|_3P|VERB|PRESENT,'2v');
  AddDeclension("ent",PLURAL|_3P|VERB|PRESENT,'2v');
//2NDIMPERFECT
  AddDeclension("ebam",SINGULAR|_1P|VERB|IMPERFECT,'2v');
  AddDeclension("ebamus",PLURAL|_1P|VERB|IMPERFECT,'2v');
  AddDeclension("ebas",SINGULAR|_2P|VERB|IMPERFECT,'2v');
  AddDeclension("ebatis",PLURAL|_2P|VERB|IMPERFECT,'2v');
  AddDeclension("ebat",SINGULAR|_3P|VERB|IMPERFECT,'2v');
  AddDeclension("ebant",PLURAL|_3P|VERB|IMPERFECT,'2v');
//2ND FUTURE
  AddDeclension("ebo",SINGULAR|_1P|VERB|FUTURE,'2v');
  AddDeclension("ebimus",PLURAL|_1P|VERB|FUTURE,'2v');
  AddDeclension("ebis",SINGULAR|_2P|VERB|FUTURE,'2v');
  AddDeclension("ebitis",PLURAL|_2P|VERB|FUTURE,'2v');
  AddDeclension("ebit",SINGULAR|_3P|VERB|FUTURE,'2v');
  AddDeclension("ebunt",PLURAL|_3P|VERB|FUTURE,'2v');
//2ND PERFECT
  AddDeclension("i",SINGULAR|_1P|VERB|PERFECT,'2v');
  AddDeclension("imus",PLURAL|_1P|VERB|PERFECT,'2v');
  AddDeclension("iti",SINGULAR|_2P|VERB|PERFECT,'2v');
  AddDeclension("itis",PLURAL|_2P|VERB|PERFECT,'2v');
  AddDeclension("it",SINGULAR|_3P|VERB|PERFECT,'2v');
  AddDeclension("erunt",PLURAL|_3P|VERB|PERFECT,'2v');
  AddDeclension("ere",PLURAL|_3P|VERB|PERFECT,'2v');
//2ND PLUPERFECT
  AddDeclension("eram",SINGULAR|_1P|VERB|PLUPERFECT,'2v');
  AddDeclension("eramus",PLURAL|_1P|VERB|PLUPERFECT,'2v');
  AddDeclension("eras",SINGULAR|_2P|VERB|PLUPERFECT,'2v');
  AddDeclension("eratis",PLURAL|_2P|VERB|PLUPERFECT,'2v');
  AddDeclension("erat",SINGULAR|_3P|VERB|PLUPERFECT,'2v');
  AddDeclension("erant",PLURAL|_3P|VERB|PLUPERFECT,'2v');
//2ND FUTURE PERFECT
  AddDeclension("ero",SINGULAR|_1P|VERB|PERFECT,'2v');
  AddDeclension("erimus",PLURAL|_1P|VERB|PERFECT,'2v');
  AddDeclension("eras",SINGULAR|_2P|VERB|PERFECT,'2v');
  AddDeclension("eratis",PLURAL|_2P|VERB|PERFECT,'2v');
  AddDeclension("erit",SINGULAR|_3P|VERB|PERFECT,'2v');
  AddDeclension("erint",PLURAL|_3P|VERB|PERFECT,'2v');
//2ND PRESENT PASSIVE
  AddDeclension("eor",SINGULAR|_1P|VERB|PRESENT,'2v');
  AddDeclension("emur",PLURAL|_1P|VERB|PRESENT,'2v');
  AddDeclension("eris",SINGULAR|_2P|VERB|PRESENT,'2v');
  AddDeclension("ere",SINGULAR|_2P|VERB|PRESENT,'2v');
  AddDeclension("emini",PLURAL|_2P|VERB|PRESENT,'2v');
  AddDeclension("etur",SINGULAR|_3P|VERB|PRESENT,'2v');
  AddDeclension("entur",PLURAL|_3P|VERB|PRESENT,'2v');
//2NDIMPERFECT PASSIVE
  AddDeclension("ebar",SINGULAR|_1P|VERB|IMPERFECT,'2v');
  AddDeclension("ebamur",PLURAL|_1P|VERB|IMPERFECT,'2v');
  AddDeclension("ebaris",SINGULAR|_2P|VERB|IMPERFECT,'2v');
  AddDeclension("ebare",SINGULAR|_2P|VERB|IMPERFECT,'2v');
  AddDeclension("ebamini",PLURAL|_2P|VERB|IMPERFECT,'2v');
  AddDeclension("ebitur",SINGULAR|_3P|VERB|IMPERFECT,'2v');
  AddDeclension("ebuntur",PLURAL|_3P|VERB|IMPERFECT,'2v');
//2ND FUTURE PASSIVE
  AddDeclension("ebor",SINGULAR|_1P|VERB|FUTURE,'2v');
  AddDeclension("ebimur",PLURAL|_1P|VERB|FUTURE,'2v');
  AddDeclension("eberis",SINGULAR|_2P|VERB|FUTURE,'2v');
  AddDeclension("ebere",SINGULAR|_2P|VERB|FUTURE,'2v');
  AddDeclension("ebimini",PLURAL|_2P|VERB|FUTURE,'2v');
  AddDeclension("ebitur",SINGULAR|_3P|VERB|FUTURE,'2v');
  AddDeclension("ebuntur",PLURAL|_3P|VERB|FUTURE,'2v');
//2ND IMPERATIVE
  AddDeclension("e",IMPERATIVE|_2P|SINGULAR|VERB,'2v');
  AddDeclension("ete",IMPERATIVE|_2P|PLURAL|VERB,'2v');
  AddDeclension("eto",IMPERATIVE|_2P|SINGULAR|VERB|FUTURE,'2v');
  AddDeclension("etote",IMPERATIVE|_2P|PLURAL|VERB|FUTURE,'2v');
  AddDeclension("eto",IMPERATIVE|_3P|SINGULAR|VERB|FUTURE,'2v');
  AddDeclension("ento",IMPERATIVE|_3P|PLURAL|VERB|FUTURE,'2v');
  AddDeclension("ere",IMPERATIVE|_2P|SINGULAR|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("emini",IMPERATIVE|_2P|PLURAL|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("etor",IMPERATIVE|_2P|SINGULAR|VERB|SUBJUNCTIVE|FUTURE,'2v');
  AddDeclension("etor",IMPERATIVE|_3P|SINGULAR|VERB|SUBJUNCTIVE|FUTURE,'2v');
  AddDeclension("entor",IMPERATIVE|_3P|PLURAL|VERB|SUBJUNCTIVE|FUTURE,'2v');
//2nd INFINITIVE
  AddDeclension("ere",INFINITIVE,'2v');
  AddDeclension("isse",INFINITIVE|IMPERFECT,'2v');
  AddDeclension("eri",INFINITIVE|SUBJUNCTIVE,'2v');
/*//PARTICIPLES This is handled by AddWordByPrincibleParts
  AddDeclension("ens",PARTICIPLE,'2v');
  AddDeclension("entis",PARTICIPLE,'2v');
  AddDeclension("urus",PARTICIPLE|FUTURE,'2v');
  AddDeclension("us",PARTICIPLE|SUBJUNCTIVE|PERFECT,'2v');
*/
//2nd GERIUND
  AddDeclension("endi",GERUND|GENITIVE,'2v');
  AddDeclension("endo",GERUND|DATIVE,'2v');
  AddDeclension("endum",GERUND|ACCUSATIVE,'2v');
  AddDeclension("endo",GERUND|ABLATIVE,'2v');

//2nd SUBJUNCTIVE
  AddDeclension("eam",SINGULAR|_1P|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("eamus",PLURAL|_1P|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("eas",SINGULAR|_2P|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("eatis",PLURAL|_2P|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("eat",SINGULAR|_3P|VERB|SUBJUNCTIVE,'2v');
  AddDeclension("eant",PLURAL|_3P|VERB|SUBJUNCTIVE,'2v');
//3nd conjuation indicative
  AddDeclension("o",SINGULAR|_1P|VERB,'3v');
  AddDeclension("imus",PLURAL|_1P|VERB,'3v');
  AddDeclension("is",SINGULAR|_2P|VERB,'3v');
  AddDeclension("itis",PLURAL|_2P|VERB,'3v');
  AddDeclension("it",SINGULAR|_3P|VERB,'3v');
  AddDeclension("unt",PLURAL|_3P|VERB,'3v');

  AddDeclension("ebam",SINGULAR|_1P|VERB|IMPERFECT,'3v');
  AddDeclension("ebamus",PLURAL|_1P|VERB|IMPERFECT,'3v');
  AddDeclension("ebas",SINGULAR|_2P|VERB|IMPERFECT,'3v');
  AddDeclension("ebatis",PLURAL|_2P|VERB|IMPERFECT,'3v');
  AddDeclension("ebat",SINGULAR|_3P|VERB|IMPERFECT,'3v');
  AddDeclension("ebant",PLURAL|_3P|VERB|IMPERFECT,'3v');

  AddDeclension("am",SINGULAR|_1P|VERB|FUTURE,'3v');
  AddDeclension("emus",PLURAL|_1P|VERB|FUTURE,'3v');
  AddDeclension("es",SINGULAR|_2P|VERB|FUTURE,'3v');
  AddDeclension("etis",PLURAL|_2P|VERB|FUTURE,'3v');
  AddDeclension("et",SINGULAR|_3P|VERB|FUTURE,'3v');
  AddDeclension("ent",PLURAL|_3P|VERB|FUTURE,'3v');

  AddDeclension("i",SINGULAR|_1P|VERB|PERFECT,'3v');
  AddDeclension("imus",PLURAL|_1P|VERB|PERFECT,'3v');
  AddDeclension("isti",SINGULAR|_2P|VERB|PERFECT,'3v');
  AddDeclension("istis",PLURAL|_2P|VERB|PERFECT,'3v');
  AddDeclension("it",SINGULAR|_3P|VERB|PERFECT,'3v');
  AddDeclension("erunt",PLURAL|_3P|VERB|PERFECT,'3v');
  AddDeclension("ere",PLURAL|_3P|VERB|PERFECT,'3v');

  AddDeclension("eram",SINGULAR|_1P|VERB|PLUPERFECT,'3v');
  AddDeclension("eremus",PLURAL|_1P|VERB|PLUPERFECT,'3v');
  AddDeclension("eres",SINGULAR|_2P|VERB|PLUPERFECT,'3v');
  AddDeclension("eretis",PLURAL|_2P|VERB|PLUPERFECT,'3v');
  AddDeclension("eret",SINGULAR|_3P|VERB|PLUPERFECT,'3v');
  AddDeclension("erent",PLURAL|_3P|VERB|PLUPERFECT,'3v');

  AddDeclension("am",SINGULAR|_1P|VERB|FUTURE|PERFECT,'3v');
  AddDeclension("emus",PLURAL|_1P|VERB|FUTURE|PERFECT,'3v');
  AddDeclension("es",SINGULAR|_2P|VERB|FUTURE|PERFECT,'3v');
  AddDeclension("etis",PLURAL|_2P|VERB|FUTURE|PERFECT,'3v');
  AddDeclension("et",SINGULAR|_3P|VERB|FUTURE|PERFECT,'3v');
  AddDeclension("ent",PLURAL|_3P|VERB|FUTURE|PERFECT,'3v');

  AddDeclension("or",SINGULAR|_1P|VERB|PASSIVE,'3v');
  AddDeclension("imur",PLURAL|_1P|VERB|PASSIVE,'3v');
  AddDeclension("ire",SINGULAR|_2P|VERB|PASSIVE,'3v');
  AddDeclension("iris",SINGULAR|_2P|VERB|PASSIVE,'3v');
  AddDeclension("imini",PLURAL|_2P|VERB|PASSIVE,'3v');
  AddDeclension("itur",SINGULAR|_3P|VERB|PASSIVE,'3v');
  AddDeclension("untur",PLURAL|_3P|VERB,'3v');

  AddDeclension("ebar",SINGULAR|_1P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebamur",PLURAL|_1P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebaris",SINGULAR|_2P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebare",SINGULAR|_2P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebamini",PLURAL|_2P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebatur",SINGULAR|_3P|VERB|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ebantur",PLURAL|_3P|VERB|IMPERFECT|PASSIVE,'3v');

  AddDeclension("ar",SINGULAR|_1P|VERB|FUTURE|PASSIVE,'3v');
  AddDeclension("emur",PLURAL|_1P|VERB|FUTURE|PASSIVE,'3v');
  AddDeclension("eris",SINGULAR|_2P|VERB|FUTURE|PASSIVE,'3v');
  AddDeclension("emini",PLURAL|_2P|VERB|FUTURE|PASSIVE,'3v');
  AddDeclension("etur",SINGULAR|_3P|VERB|FUTURE|PASSIVE,'3v');
  AddDeclension("entur",PLURAL|_3P|VERB|FUTURE|PASSIVE,'3v');
//3rd  subjunctive
  AddDeclension("am",SINGULAR|_1P|VERB|SUBJUNCTIVE,'3v');
  AddDeclension("amus",PLURAL|_1P|VERB|SUBJUNCTIVE,'3v');
  AddDeclension("as",SINGULAR|_2P|VERB|SUBJUNCTIVE,'3v');
  AddDeclension("atis",PLURAL|_2P|VERB|SUBJUNCTIVE,'3v');
  AddDeclension("at",SINGULAR|_3P|VERB|SUBJUNCTIVE,'3v');
  AddDeclension("ant",PLURAL|_3P|VERB|SUBJUNCTIVE,'3v');

  AddDeclension("erem",SINGULAR|_1P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');
  AddDeclension("ereimus",PLURAL|_1P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');
  AddDeclension("eres",SINGULAR|_2P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');
  AddDeclension("eretis",PLURAL|_2P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');
  AddDeclension("eret",SINGULAR|_3P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');
  AddDeclension("erent",PLURAL|_3P|VERB||SUBJUNCTIVE|IMPERFECT,'3v');

  AddDeclension("erim",SINGULAR|_1P|VERB||SUBJUNCTIVE|PERFECT,'3v');
  AddDeclension("erimus",PLURAL|_1P|VERB||SUBJUNCTIVE|PERFECT,'3v');
  AddDeclension("eris",SINGULAR|_2P|VERB||SUBJUNCTIVE|PERFECT,'3v');
  AddDeclension("eritis",PLURAL|_2P|VERB||SUBJUNCTIVE|PERFECT,'3v');
  AddDeclension("erit",SINGULAR|_3P|VERB||SUBJUNCTIVE|PERFECT,'3v');
  AddDeclension("erint",PLURAL|_3P|VERB||SUBJUNCTIVE|PERFECT,'3v');

  AddDeclension("issem",SINGULAR|_1P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
  AddDeclension("issemus",PLURAL|_1P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
  AddDeclension("isses",SINGULAR|_2P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
  AddDeclension("issetis",PLURAL|_2P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
  AddDeclension("erit",SINGULAR|_3P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
  AddDeclension("erint",PLURAL|_3P|VERB||SUBJUNCTIVE|PLUPERFECT,'3v');
//3rd Passives
  AddDeclension("ar",SINGULAR|_1P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("amur",PLURAL|_1P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("aris",SINGULAR|_2P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("are",SINGULAR|_2P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("amini",PLURAL|_2P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("atur",SINGULAR|_3P|VERB|SUBJUNCTIVE|PASSIVE,'3v');
  AddDeclension("antur",PLURAL|_3P|VERB|SUBJUNCTIVE|PASSIVE,'3v');

  AddDeclension("erer",SINGULAR|_1P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("eremus",PLURAL|_1P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("ereris",SINGULAR|_2P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("erere",SINGULAR|_2P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("eretis",PLURAL|_2P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("eret",SINGULAR|_3P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
  AddDeclension("erent",PLURAL|_3P|VERB||SUBJUNCTIVE|IMPERFECT|PASSIVE,'3v');
//3rd Imperatives
  AddDeclension("e",SINGULAR|_2P|VERB|IMPERATIVE,'3v');
  AddDeclension("ite",PLURAL|_2P|VERB|IMPERATIVE,'3v');
  AddDeclension("ito",SINGULAR|_2P|VERB|IMPERATIVE|FUTURE,'3v');
  AddDeclension("itote",PLURAL|_2P|VERB|IMPERATIVE|FUTURE,'3v');
  AddDeclension("ito",SINGULAR|_3P|VERB|IMPERATIVE|FUTURE,'3v');
  AddDeclension("unto",PLURAL|_3P|VERB|IMPERATIVE|FUTURE,'3v');

  AddDeclension("ere",SINGULAR|_2P|VERB|IMPERATIVE|PASSIVE,'3v');
  AddDeclension("imini",PLURAL|_2P|VERB|IMPERATIVE|PASSIVE,'3v');
  AddDeclension("itor",SINGULAR|_2P|VERB|IMPERATIVE|FUTURE|PASSIVE,'3v');
  AddDeclension("itor",SINGULAR|_3P|VERB|IMPERATIVE|FUTURE|PASSIVE,'3v');
  AddDeclension("untor",PLURAL|_3P|VERB|IMPERATIVE|FUTURE|PASSIVE,'3v');
//Infintives
  AddDeclension("ere",INFINITIVE,'3v');
  AddDeclension("isse",INFINITIVE|PERFECT,'3v');
  AddDeclension("regi",INFINITIVE|PASSIVE,'3v');
//This is handled by AddWordByPrincibleParts
/*
//Participles
  AddDeclension("ens",PARTICIPLE,'3v');
  AddDeclension("entis",PARTICIPLE,'3v');
  AddDeclension("urus",PARTICIPLE|FUTURE,'3v');
*/
//3rd gerunds
  AddDeclension("endi",GERUND|GENITIVE,'3v');
  AddDeclension("endo",GERUND|DATIVE,'3v');
  AddDeclension("endum",GERUND|ACCUSATIVE,'3v');
  AddDeclension("endo",GERUND|ABLATIVE,'3v');


//3rd io
  AddDeclension("io",SINGULAR|_1P|VERB,'3iov');
  AddDeclension("imus",PLURAL|_1P|VERB,'3iov');
  AddDeclension("is",SINGULAR|_2P|VERB,'3iov');
  AddDeclension("itis",PLURAL|_2P|VERB,'3iov');
  AddDeclension("it",SINGULAR|_3P|VERB,'3iov');
  AddDeclension("iunt",PLURAL|_3P|VERB,'3iov');
  AddDeclension("ior",SINGULAR|_1P|VERB|PASSIVE,'3iov');
  AddDeclension("imur",PLURAL|_1P|VERB|PASSIVE,'3iov');
  AddDeclension("iris",SINGULAR|_2P|VERB|PASSIVE,'3iov');
  AddDeclension("ire",SINGULAR|_2P|VERB|PASSIVE,'3iov');
  AddDeclension("imini",PLURAL|_2P|VERB|PASSIVE,'3iov');
  AddDeclension("itur",SINGULAR|_3P|VERB|PASSIVE,'3iov');
  AddDeclension("iuntur",PLURAL|_3P|VERB|PASSIVE,'3iov');

  AddDeclension("iebam",SINGULAR|_1P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebamus",PLURAL|_1P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebas",SINGULAR|_2P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebatis",PLURAL|_2P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebat",SINGULAR|_3P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebant",PLURAL|_3P|VERB|IMPERFECT,'3iov');
  AddDeclension("iebar",SINGULAR|_1P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebammur",PLURAL|_1P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebaris",SINGULAR|_2P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebare",SINGULAR|_2P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebamini",PLURAL|_2P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebatur",SINGULAR|_3P|VERB|PASSIVE|IMPERFECT,'3iov');
  AddDeclension("iebantur",PLURAL|_3P|VERB|PASSIVE|IMPERFECT,'3iov');

  AddDeclension("iam",SINGULAR|_1P|VERB|FUTURE,'3iov');
  AddDeclension("iemus",PLURAL|_1P|VERB|FUTURE,'3iov');
  AddDeclension("ies",SINGULAR|_2P|VERB|FUTURE,'3iov');
  AddDeclension("ietis",PLURAL|_2P|VERB|FUTURE,'3iov');
  AddDeclension("iet",SINGULAR|_3P|VERB|FUTURE,'3iov');
  AddDeclension("ient",PLURAL|_3P|VERB|FUTURE,'3iov');
  AddDeclension("ier",SINGULAR|_1P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("iemur",PLURAL|_1P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("ieris",SINGULAR|_2P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("iere",SINGULAR|_2P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("iemini",PLURAL|_2P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("ietur",SINGULAR|_3P|VERB|PASSIVE|FUTURE,'3iov');
  AddDeclension("ientur",PLURAL|_3P|VERB|PASSIVE|FUTURE,'3iov');

  AddDeclension("i",SINGULAR|_1P|VERB|PERFECT,'3iov');
  AddDeclension("imus",PLURAL|_1P|VERB|PERFECT,'3iov');
  AddDeclension("isti",SINGULAR|_2P|VERB|PERFECT,'3iov');
  AddDeclension("istis",PLURAL|_2P|VERB|PERFECT,'3iov');
  AddDeclension("it",SINGULAR|_3P|VERB|PERFECT,'3iov');
  AddDeclension("erunt",PLURAL|_3P|VERB|PERFECT,'3iov');
  AddDeclension("ere",PLURAL|_3P|VERB|PERFECT,'3iov');

  AddDeclension("eram",SINGULAR|_1P|VERB|PLUPERFECT,'3iov');
  AddDeclension("eramus",PLURAL|_1P|VERB|PLUPERFECT,'3iov');
  AddDeclension("eras",SINGULAR|_2P|VERB|PLUPERFECT,'3iov');
  AddDeclension("eratis",PLURAL|_2P|VERB|PLUPERFECT,'3iov');
  AddDeclension("erat",SINGULAR|_3P|VERB|PLUPERFECT,'3iov');
  AddDeclension("erant",PLURAL|_3P|VERB|PLUPERFECT,'3iov');

  AddDeclension("ero",SINGULAR|_1P|VERB|FUTURE|PERFECT,'3iov');
  AddDeclension("erimus",PLURAL|_1P|VERB|FUTURE|PERFECT,'3iov');
  AddDeclension("eris",SINGULAR|_2P|VERB|FUTURE|PERFECT,'3iov');
  AddDeclension("eritis",PLURAL|_2P|VERB|FUTURE|PERFECT,'3iov');
  AddDeclension("erit",SINGULAR|_3P|VERB|FUTURE|PERFECT,'3iov');
  AddDeclension("erint",PLURAL|_3P|VERB|FUTURE|PERFECT,'3iov');
//3io Sunjucntives
  AddDeclension("iam",SINGULAR|_1P|VERB|SUBJUNCTIVE,'3iov');
  AddDeclension("iamus",PLURAL|_1P|VERB|SUBJUNCTIVE,'3iov');
  AddDeclension("ias",SINGULAR|_2P|VERB|SUBJUNCTIVE,'3iov');
  AddDeclension("iatis",PLURAL|_2P|VERB|SUBJUNCTIVE,'3iov');
  AddDeclension("iat",SINGULAR|_3P|VERB|SUBJUNCTIVE,'3iov');
  AddDeclension("iant",PLURAL|_3P|VERB|SUBJUNCTIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iar",SINGULAR|_1P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iamur",PLURAL|_1P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iaris",SINGULAR|_2P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iare",SINGULAR|_2P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iamini",PLURAL|_2P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iatur",SINGULAR|_3P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');
  AddDeclension("iantur",PLURAL|_3P|VERB|PASSIVE|SUBJUNCTIVE,'3iov');

  AddDeclension("erem",SINGULAR|_1P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eremus",PLURAL|_1P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eres",SINGULAR|_2P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eretis",PLURAL|_2P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eret",SINGULAR|_3P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erent",PLURAL|_3P|VERB|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erer",SINGULAR|_1P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eremur",PLURAL|_1P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("ereris",SINGULAR|_2P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erere",SINGULAR|_2P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eremini",PLURAL|_2P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eretur",SINGULAR|_3P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erentur",PLURAL|_3P|VERB|PASSIVE|IMPERFECT|SUBJUNCTIVE,'3iov');

  AddDeclension("erim",SINGULAR|_1P|VERB|PERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erimus",PLURAL|_1P|VERB|PERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eristi",SINGULAR|_2P|VERB|PERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eristis",PLURAL|_2P|VERB|PERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erit",SINGULAR|_3P|VERB|PERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("erint",PLURAL|_3P|VERB|PERFECT|SUBJUNCTIVE,'3iov');

  AddDeclension("issem",SINGULAR|_1P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("issemus",PLURAL|_1P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eris",SINGULAR|_2P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("eritis",PLURAL|_2P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("isset",SINGULAR|_3P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
  AddDeclension("issent",PLURAL|_3P|VERB|PLUPERFECT|SUBJUNCTIVE,'3iov');
//3io imperative
  AddDeclension("e",SINGULAR|_2P|VERB|IMPERATIVE,'3iov');
  AddDeclension("ite",PLURAL|_2P|VERB|IMPERATIVE,'3iov');
  AddDeclension("ere",SINGULAR|_2P|VERB|IMPERATIVE|PASSIVE,'3iov');
  AddDeclension("imini",PLURAL|_2P|VERB|IMPERATIVE|PASSIVE,'3iov');

  AddDeclension("ito",SINGULAR|_2P|VERB|IMPERATIVE|FUTURE,'3iov');
  AddDeclension("itote",PLURAL|_2P|VERB|IMPERATIVE|FUTURE,'3iov');
  AddDeclension("itor",SINGULAR|_2P|VERB|IMPERATIVE|PASSIVE|FUTURE,'3iov');
  AddDeclension("ito",SINGULAR|_3P|VERB|IMPERATIVE|FUTURE,'3iov');
  AddDeclension("itunto",PLURAL|_3P|VERB|IMPERATIVE|FUTURE,'3iov');
  AddDeclension("itor",SINGULAR|_3P|VERB|IMPERATIVE|PASSIVE|FUTURE,'3iov');
  AddDeclension("iuntor",PLURAL|_3P|VERB|IMPERATIVE|FUTURE|PASSIVE,'3iov');
//3io infintiives
  AddDeclension("ere",INFINITIVE,'3iov');
  AddDeclension("i",INFINITIVE|PASSIVE,'3iov');
  AddDeclension("isse",INFINITIVE|PERFECT,'3iov');
//This is handled by AddWordByPrincibleParts
/*
//3io Participles
  AddDeclension("iens",PARTICIPLE,'3iov');
  AddDeclension("entis",PARTICIPLE,'3iov');
  AddDeclension("urus",PARTICIPLE|FUTURE,'3iov');
  AddDeclension("us",PARTICIPLE|PERFECT|PASSIVE,'3iov');
  AddDeclension("iendus",PARTICIPLE|FUTURE|PASSIVE,'3iov');
*/
//3io gerunds
  AddDeclension("endi",GERUND|GENITIVE,'3iov');
  AddDeclension("endo",GERUND|DATIVE,'3iov');
  AddDeclension("endum",GERUND|ACCUSATIVE,'3iov');
  AddDeclension("endo",GERUND|ABLATIVE,'3iov');
//Adfjectives
  AddDeclension("",ADJECTIVE|SINGULAR|MASCULINE|NOMITIVE,'adj12');
  AddDeclension("us",ADJECTIVE|SINGULAR|MASCULINE|NOMITIVE,'adj12');
  AddDeclension("i",ADJECTIVE|PLURAL|MASCULINE|NOMITIVE,'adj12');
  AddDeclension("i",ADJECTIVE|SINGULAR|GENITIVE|MASCULINE,'adj12');
  AddDeclension("orum",ADJECTIVE|PLURAL|GENITIVE|MASCULINE,'adj12');
  AddDeclension("o",ADJECTIVE|SINGULAR|DATIVE|MASCULINE,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|DATIVE|MASCULINE,'adj12');
  AddDeclension("um",ADJECTIVE|SINGULAR|ACCUSATIVE|MASCULINE,'adj12');
  AddDeclension("os",ADJECTIVE|PLURAL|ACCUSATIVE|MASCULINE,'adj12');
  AddDeclension("o",ADJECTIVE|SINGULAR|ABLATIVE|MASCULINE,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|ABLATIVE|MASCULINE,'adj12'); 

  AddDeclension("a",ADJECTIVE|SINGULAR|FEMININE|NOMITIVE,'adj12');
  AddDeclension("ae",ADJECTIVE|PLURAL|FEMININE|NOMITIVE,'adj12');
  AddDeclension("ae",ADJECTIVE|SINGULAR|GENITIVE|FEMININE,'adj12');
  AddDeclension("arum",ADJECTIVE|PLURAL|GENITIVE|FEMININE,'adj12');
  AddDeclension("ae",ADJECTIVE|SINGULAR|DATIVE|FEMININE,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|DATIVE|FEMININE,'adj12');
  AddDeclension("am",ADJECTIVE|SINGULAR|ACCUSATIVE|FEMININE,'adj12');
  AddDeclension("as",ADJECTIVE|PLURAL|ACCUSATIVE|FEMININE,'adj12');
  AddDeclension("a",ADJECTIVE|SINGULAR|ABLATIVE|FEMININE,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|ABLATIVE|FEMININE,'adj12'); 

  AddDeclension("um",ADJECTIVE|SINGULAR|NEUTER|NOMITIVE,'adj12');
  AddDeclension("a",ADJECTIVE|PLURAL|NEUTER|NOMITIVE,'adj12');
  AddDeclension("i",ADJECTIVE|SINGULAR|GENITIVE|NEUTER,'adj12');
  AddDeclension("orum",ADJECTIVE|PLURAL|GENITIVE|NEUTER,'adj12');
  AddDeclension("o",ADJECTIVE|SINGULAR|DATIVE|NEUTER,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|DATIVE|NEUTER,'adj12');
  AddDeclension("um",ADJECTIVE|SINGULAR|ACCUSATIVE|NEUTER,'adj12');
  AddDeclension("a",ADJECTIVE|PLURAL|ACCUSATIVE|NEUTER,'adj12');
  AddDeclension("o",ADJECTIVE|SINGULAR|ABLATIVE|NEUTER,'adj12');
  AddDeclension("is",ADJECTIVE|PLURAL|ABLATIVE|NEUTER,'adj12'); 
//Adjectives third delcension
  //Adverbs can be made with 3rd declension adjectives
  //$BK,1$TODO$BK,0$ make it find the difference between "iter" and "er"(when stem ending with "nt")
  AddDeclension("iter",ADVERB|NEUTER,'adj3');
  AddDeclension("er",ADVERB|NEUTER,'adj3');
  AddDeclension("iter",ADJECTIVE|NEUTER,'adj3');
  AddDeclension("er",ADJECTIVE|NEUTER,'adj3');
//4th conujation
  AddDeclension("io",SINGULAR|_1P|VERB,'4v');
  AddDeclension("imus",PLURAL|_1P|VERB,'4v');
  AddDeclension("is",SINGULAR|_2P|VERB,'4v');
  AddDeclension("itis",PLURAL|_2P|VERB,'4v');
  AddDeclension("it",SINGULAR|_3P|VERB,'4v');
  AddDeclension("iunt",PLURAL|_3P|VERB,'4v');

  AddDeclension("ior",PASSIVE|SINGULAR|_1P|VERB,'4v');
  AddDeclension("imur",PASSIVE|PLURAL|_1P|VERB,'4v');
  AddDeclension("iris",PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("ire",PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("imini",PASSIVE|PLURAL|_2P|VERB,'4v');
  AddDeclension("itur",PASSIVE|SINGULAR|_3P|VERB,'4v');
  AddDeclension("iuntur",PASSIVE|PLURAL|_3P|VERB,'4v');

  AddDeclension("iebam",IMPERFECT|SINGULAR|_1P|VERB,'4v');
  AddDeclension("ibamus",IMPERFECT|PLURAL|_1P|VERB,'4v');
  AddDeclension("iebas",IMPERFECT|SINGULAR|_2P|VERB,'4v');
  AddDeclension("iebatis",IMPERFECT|PLURAL|_2P|VERB,'4v');
  AddDeclension("iet",IMPERFECT|SINGULAR|_3P|VERB,'4v');
  AddDeclension("ient",IMPERFECT|PLURAL|_3P|VERB,'4v');

  AddDeclension("iebar",IMPERFECT|PASSIVE|SINGULAR|_1P|VERB,'4v');
  AddDeclension("iebarmur",IMPERFECT|PASSIVE|PLURAL|_1P|VERB,'4v');
  AddDeclension("iebaris",IMPERFECT|PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("iebare",IMPERFECT|PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("iebamini",IMPERFECT|PASSIVE|PLURAL|_2P|VERB,'4v');
  AddDeclension("iebatur",IMPERFECT|PASSIVE|SINGULAR|_3P|VERB,'4v');
  AddDeclension("iebantur",IMPERFECT|PASSIVE|PLURAL|_3P|VERB,'4v');

  AddDeclension("iam",FUTURE|SINGULAR|_1P|VERB,'4v');
  AddDeclension("iemus",FUTURE|PLURAL|_1P|VERB,'4v');
  AddDeclension("ies",FUTURE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("ietis",FUTURE|PLURAL|_2P|VERB,'4v');
  AddDeclension("iet",FUTURE|SINGULAR|_3P|VERB,'4v');
  AddDeclension("ient",FUTURE|PLURAL|_3P|VERB,'4v');

  AddDeclension("iar",FUTURE|PASSIVE|SINGULAR|_1P|VERB,'4v');
  AddDeclension("iemur",FUTURE|PASSIVE|PLURAL|_1P|VERB,'4v');
  AddDeclension("ieris",FUTURE|PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("iere",FUTURE|PASSIVE|SINGULAR|_2P|VERB,'4v');
  AddDeclension("iemini",FUTURE|PASSIVE|PLURAL|_2P|VERB,'4v');
  AddDeclension("ietur",FUTURE|PASSIVE|SINGULAR|_3P|VERB,'4v');
  AddDeclension("ientur",FUTURE|PASSIVE|PLURAL|_3P|VERB,'4v');

  AddDeclension("i",PERFECT|SINGULAR|_1P|VERB,'4v');
  AddDeclension("imus",PERFECT|PLURAL|_1P|VERB,'4v');
  AddDeclension("isti",PERFECT|SINGULAR|_2P|VERB,'4v');
  AddDeclension("istis",PERFECT|PLURAL|_2P|VERB,'4v');
  AddDeclension("it",PERFECT|SINGULAR|_3P|VERB,'4v');
  AddDeclension("irunt",PERFECT|PLURAL|_3P|VERB,'4v');
  AddDeclension("ire",PERFECT|PLURAL|_3P|VERB,'4v');

  AddDeclension("eram",PLUPERFECT|SINGULAR|_1P|VERB,'4v');
  AddDeclension("eramus",PLUPERFECT|PLURAL|_1P|VERB,'4v');
  AddDeclension("eras",PLUPERFECT|SINGULAR|_2P|VERB,'4v');
  AddDeclension("eratis",PLUPERFECT|PLURAL|_2P|VERB,'4v');
  AddDeclension("erat",PLUPERFECT|SINGULAR|_3P|VERB,'4v');
  AddDeclension("erant",PLUPERFECT|PLURAL|_3P|VERB,'4v');

  AddDeclension("ero",FUTURE|PERFECT|SINGULAR|_1P|VERB,'4v');
  AddDeclension("erimus",FUTURE|PERFECT|PLURAL|_1P|VERB,'4v');
  AddDeclension("eris",FUTURE|PERFECT|SINGULAR|_2P|VERB,'4v');
  AddDeclension("eritis",FUTURE|PERFECT|PLURAL|_2P|VERB,'4v');
  AddDeclension("erit",FUTURE|PERFECT|SINGULAR|_3P|VERB,'4v');
  AddDeclension("erint",FUTURE|PERFECT|PLURAL|_3P|VERB,'4v');

  AddDeclension("ire",INFINITIVE,'4v');
  AddDeclension("iri",INFINITIVE|PASSIVE,'4v');
  AddDeclension("isse",INFINITIVE|PERFECT,'4v');

  AddDeclension("iendi",GERUND|GENITIVE,'4v');
  AddDeclension("iendo",GERUND|DATIVE,'4v');
  AddDeclension("iendum",GERUND|ACCUSATIVE,'4v');
  AddDeclension("iendo",GERUND|ABLATIVE,'4v');

}
InitLatin;
U0 InitDict() {
  AddWordByPrincibleParts("Christ",NOUN,"Christum","Christi");
  AddWordByPrincibleParts("Mathew",NOUN,"Matheum","Mathei");
  AddWordByPrincibleParts("Shapes",NOUN,"foramentum","formamenti");
  AddWordByPrincibleParts("one",ADJECTIVE,"unus","una"); //One
  AddWordByPrincibleParts("two",ADJECTIVE,"duo","duorem"); //Two
  AddWordByPrincibleParts("three",ADJECTIVE,"tres","trium"); //Three
  TrieAdd("ad",PREPOSITION,"towards"); //Towards
  TrieAdd("et",CONJUNCTION,"and");
  TrieAdd("atque",CONJUNCTION,"also");
  TrieAdd("ac",CONJUNCTION,"also");
  TrieAdd("etiam",CONJUNCTION,"also");
//Also
  TrieAdd("atque",CONJUNCTION,"also");
  TrieAdd("quoque",CONJUNCTION,"also");
//or thing or other
  TrieAdd("aut",CONJUNCTION,"or");
//but
  TrieAdd("sed",CONJUNCTION,"but");
  TrieAdd("autem",CONJUNCTION,"but");
  TrieAdd("verum",CONJUNCTION,"but");
//However
  TrieAdd("tamen",CONJUNCTION,"however");
//For
  TrieAdd("name",CONJUNCTION,"for");
  TrieAdd("enim",CONJUNCTION,"enim");
//Therefore
  TrieAdd("ergo",CONJUNCTION,"therefore");
  TrieAdd("igitur",CONJUNCTION,"therefore");
  TrieAdd("itaque",ADVERB|INDECLINABLE,"therefore");
//Pronouns 1st person
  TrieAdd("ego",NOMITIVE|PRONOUN|_1P|SINGULAR,"I");
  TrieAdd("nos",NOMITIVE|PRONOUN|_1P|PLURAL,"we/us");
  TrieAdd("mei",GENITIVE|PRONOUN|_1P|SINGULAR,"my");
  TrieAdd("nostrum",GENITIVE|PRONOUN|_1P|PLURAL,"ours");
  TrieAdd("mihi",DATIVE|PRONOUN|_1P|SINGULAR,"my");
  TrieAdd("nobis",DATIVE|PRONOUN|_1P|PLURAL,"ours");
  TrieAdd("me",ACCUSATIVE|PRONOUN|_1P|SINGULAR,"me");
  TrieAdd("nos",ACCUSATIVE|PRONOUN|_1P|PLURAL,"we/us");
  TrieAdd("me",ABLATIVE|PRONOUN|_1P|SINGULAR,"my");
  TrieAdd("nobis",ABLATIVE|PRONOUN|_1P|PLURAL,"we/us");
//Pronoubns 2nd persionb
  TrieAdd("tu",NOMITIVE|PRONOUN|_2P|SINGULAR,"you");
  TrieAdd("vos",NOMITIVE|PRONOUN|_2P|PLURAL,"yours");
  TrieAdd("tui",GENITIVE|PRONOUN|_2P|SINGULAR,"your");
  TrieAdd("vestrum",GENITIVE|PRONOUN|_2P|PLURAL,"yours");
  TrieAdd("tibi",DATIVE|PRONOUN|_2P|SINGULAR,"to you");
  TrieAdd("vobis",DATIVE|PRONOUN|_2P|PLURAL,"yours");
  TrieAdd("te",ACCUSATIVE|PRONOUN|_2P|SINGULAR,"you");
  TrieAdd("vos",ACCUSATIVE|PRONOUN|_2P|PLURAL,"you");
  TrieAdd("te",ABLATIVE|PRONOUN|_2P|SINGULAR,"you");
  TrieAdd("vobis",ABLATIVE|PRONOUN|_2P|PLURAL,"you");
//Pronouns demonstatrtive
  TrieAdd("hic",NOMITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("haec",NOMITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("hoc",NOMITIVE|PRONOUN|SINGULAR|DEMONSTRATIVE|ADJECTIVE,"this");

  TrieAdd("hi",NOMITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("hae",NOMITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("haec",NOMITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|ADJECTIVE,"these");

  TrieAdd("huius",GENITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"his");
  TrieAdd("huius",GENITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|ADJECTIVE,"hers");
  TrieAdd("huius",GENITIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|ADJECTIVE,"it's");

  TrieAdd("horum",GENITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("harum",GENITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("horum",GENITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|ADJECTIVE,"these");

  TrieAdd("huic",DATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("huic",DATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("huic",DATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|ADJECTIVE,"this");

  TrieAdd("his",DATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("his",DATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("his",DATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|ADJECTIVE,"these");

  TrieAdd("hunc",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("hanc",ACCUSATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("hoc",ACCUSATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|ADJECTIVE,"this");

  TrieAdd("hos",ACCUSATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("has",ACCUSATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("haec",ACCUSATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|ADJECTIVE,"these");

  TrieAdd("hoc",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("hac",ABLATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|ADJECTIVE,"this");
  TrieAdd("hoc",ABLATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|ADJECTIVE,"this");

  TrieAdd("his",ABLATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("his",ABLATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|ADJECTIVE,"these");
  TrieAdd("his",ABLATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|ADJECTIVE,"these");
//Pronouns demonstrative(2)
  TrieAdd("ille",NOMITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illa",NOMITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illud",NOMITIVE|PRONOUN|SINGULAR|DEMONSTRATIVE|DETIRMINER,"that");

  TrieAdd("illi",NOMITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illae",NOMITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illa",NOMITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"these");

  TrieAdd("illus",GENITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"his");
  TrieAdd("illus",GENITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"hers");
  TrieAdd("illus",GENITIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"it's");

  TrieAdd("illorum",GENITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illarum",GENITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illorum",GENITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"these");

  TrieAdd("illi",DATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illi",DATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illi",DATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"that");

  TrieAdd("illis",DATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illis",DATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illis",DATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"these");

  TrieAdd("illum",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illam",ACCUSATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illud",ACCUSATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"that");

  TrieAdd("illos",ACCUSATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illas",ACCUSATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illa",ACCUSATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"these");

  TrieAdd("illo",ABLATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illa",ABLATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"that");
  TrieAdd("illo",ABLATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"that");

  TrieAdd("illis",ABLATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illis",ABLATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"these");
  TrieAdd("illis",ABLATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"these");
//This,these,that those
  TrieAdd("is",NOMITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"he");
  TrieAdd("ea",NOMITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"she");
  TrieAdd("id",NOMITIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"that");

  TrieAdd("ei",NOMITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eae",NOMITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("ea",NOMITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"those");

  TrieAdd("eius",GENITIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"his");
  TrieAdd("eius",GENITIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"hers");
  TrieAdd("eius",GENITIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"it's");

  TrieAdd("eorum",GENITIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eorum",GENITIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eorum",GENITIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"those");

  TrieAdd("ei",DATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"he");
  TrieAdd("ei",DATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"she");
  TrieAdd("ei",DATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"it");

  TrieAdd("eis",DATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eis",DATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eis",DATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"those");

  TrieAdd("eum",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"he");
  TrieAdd("eam",ACCUSATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"she");
  TrieAdd("id",ACCUSATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"it");

  TrieAdd("eos",ACCUSATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eas",ACCUSATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("ea",ACCUSATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"those");

  TrieAdd("eo",ABLATIVE|PRONOUN|SINGULAR|MASCULINE|DEMONSTRATIVE|DETIRMINER,"he");
  TrieAdd("ea",ABLATIVE|PRONOUN|SINGULAR|FEMININE|DEMONSTRATIVE|DETIRMINER,"she");
  TrieAdd("eo",ABLATIVE|PRONOUN|SINGULAR|NEUTER|DEMONSTRATIVE|DETIRMINER,"it");

  TrieAdd("eis",ABLATIVE|PRONOUN|PLURAL|MASCULINE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eis",ABLATIVE|PRONOUN|PLURAL|FEMININE|DEMONSTRATIVE|DETIRMINER,"them");
  TrieAdd("eis",ABLATIVE|PRONOUN|PLURAL|NEUTER|DEMONSTRATIVE|DETIRMINER,"those");
//Relative pronouns TODO
  TrieAdd("qui",NOMITIVE|PRONOUN|SINGULAR|MASCULINE|RELATIVE,"who");
  TrieAdd("quae",NOMITIVE|PRONOUN|SINGULAR|FEMININE|RELATIVE,"who");
  TrieAdd("quod",NOMITIVE|PRONOUN|SINGULAR|NEUTER|RELATIVE,"who");

  TrieAdd("qui",NOMITIVE|PRONOUN|PLURAL|MASCULINE|RELATIVE,"which");
  TrieAdd("quae",NOMITIVE|PRONOUN|PLURAL|FEMININE|RELATIVE,"which");
  TrieAdd("quae",NOMITIVE|PRONOUN|PLURAL|NEUTER|RELATIVE,"which");

  TrieAdd("cuius",GENITIVE|PRONOUN|SINGULAR|MASCULINE|RELATIVE,"who");
  TrieAdd("cuius",GENITIVE|PRONOUN|SINGULAR|FEMININE|RELATIVE,"who");
  TrieAdd("cuius",GENITIVE|PRONOUN|SINGULAR|NEUTER|RELATIVE,"who");

  TrieAdd("quorum",GENITIVE|PRONOUN|PLURAL|MASCULINE|RELATIVE,"which");
  TrieAdd("quorum",GENITIVE|PRONOUN|PLURAL|FEMININE|RELATIVE,"which");
  TrieAdd("quorum",GENITIVE|PRONOUN|PLURAL|NEUTER|RELATIVE,"which");

  TrieAdd("cui",DATIVE|PRONOUN|SINGULAR|MASCULINE|RELATIVE,"who");
  TrieAdd("cui",DATIVE|PRONOUN|SINGULAR|FEMININE|RELATIVE,"who");
  TrieAdd("cui",DATIVE|PRONOUN|SINGULAR|NEUTER|RELATIVE,"who");

  TrieAdd("quibus",DATIVE|PRONOUN|PLURAL|MASCULINE|RELATIVE,"which");
  TrieAdd("quibus",DATIVE|PRONOUN|PLURAL|FEMININE|RELATIVE,"which");
  TrieAdd("quibus",DATIVE|PRONOUN|PLURAL|NEUTER|RELATIVE,"which");

  TrieAdd("quem",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|RELATIVE,"who");
  TrieAdd("quem",ACCUSATIVE|PRONOUN|SINGULAR|FEMININE|RELATIVE,"who");
  TrieAdd("quem",ACCUSATIVE|PRONOUN|SINGULAR|NEUTER|RELATIVE,"who");

  TrieAdd("quos",ACCUSATIVE|PRONOUN|PLURAL|MASCULINE|RELATIVE,"which");
  TrieAdd("quas",ACCUSATIVE|PRONOUN|PLURAL|FEMININE|RELATIVE,"which");
  TrieAdd("quae",ACCUSATIVE|PRONOUN|PLURAL|NEUTER|RELATIVE,"which");

  TrieAdd("quo",ACCUSATIVE|PRONOUN|SINGULAR|MASCULINE|RELATIVE,"who");
  TrieAdd("qua",ABLATIVE|PRONOUN|SINGULAR|FEMININE|RELATIVE,"who");
  TrieAdd("quo",ABLATIVE|PRONOUN|SINGULAR|NEUTER|RELATIVE,"who");

  TrieAdd("quibus",ABLATIVE|PRONOUN|PLURAL|MASCULINE|RELATIVE,"which");
  TrieAdd("quibus",ABLATIVE|PRONOUN|PLURAL|FEMININE|RELATIVE,"which");
  TrieAdd("quibus",ABLATIVE|PRONOUN|PLURAL|NEUTER|RELATIVE,"which");


  //Prepositions
  TrieAdd("ab",PREPOSITION,"away from"); //away from(ablative)
  TrieAdd("a",PREPOSITION,"away from"); //away from(ablative)
  TrieAdd("ex",PREPOSITION,"out of"); //out of(ablative)
  TrieAdd("e",PREPOSITION,"out of"); //out of(ablative)
  TrieAdd("de",PREPOSITION,"from,about"); //down from(ablative)
  TrieAdd("in",PREPOSITION,"in"); //in (ablative)
  TrieAdd("cum",PREPOSITION,"with"); //with(ablative)

  TrieAdd("in",PREPOSITION,"into"); //itno(accusative)
  TrieAdd("ab",PREPOSITION,"towards"); //toward (accusative)
  TrieAdd("circum",PREPOSITION,"around"); //around (accusative)
  TrieAdd("supra",PREPOSITION,"above"); //above(accusative)

  //Interogitives
  TrieAdd("ubi",PRONOUN|INTEROGITIVE|ACCUSATIVE,"where"); //Where
  TrieAdd("quo",PRONOUN|INTEROGITIVE|ACCUSATIVE,"where"); //Where (are you going)
  TrieAdd("cur",PRONOUN|INTEROGITIVE|ACCUSATIVE,"what"); //What reason
  TrieAdd("quomondo",PRONOUN|INTEROGITIVE|ACCUSATIVE,"how"); //How
  TrieAdd("quid",PRONOUN|INTEROGITIVE|ACCUSATIVE,"what"); //What is it
  TrieAdd("quis",PRONOUN|INTEROGITIVE|ACCUSATIVE,"why"); //Who is it 

//Conjunctions
  TrieAdd("vel",CONJUNCTION|INDECLINABLE,"or");

//Adverb
  TrieAdd("num",ADVERB|INDECLINABLE,"hopefully not"); //Hopefully not
  TrieAdd("nonne",ADVERB|INDECLINABLE,"hopefully"); //Hopefully
  TrieAdd("quando",ADVERB|INDECLINABLE,"when"); //when X happens
  TrieAdd("quando",CONJUNCTION|INDECLINABLE,"when"); //when X happens
 
//Irregulars
  //To Wish

  TrieAdd("volo",_1P|VERB|SINGULAR,"wish");
  TrieAdd("vis",_2P|VERB|SINGULAR,"wish");
  TrieAdd("vult",_3P|VERB|SINGULAR,"wish");
  TrieAdd("volumus",_1P|VERB|PLURAL,"wish");
  TrieAdd("vultis",_2P|VERB|PLURAL,"wish");
  TrieAdd("vulunt",_3P|VERB|PLURAL,"wish");
 //Prefer
  TrieAdd("malo",_1P|VERB|SINGULAR,"prefer");
  TrieAdd("mavis",_2P|VERB|SINGULAR,"prefer");
  TrieAdd("mavult",_3P|VERB|SINGULAR,"prefer");
  TrieAdd("malumus",_1P|VERB|PLURAL,"prefer");
  TrieAdd("mavultis",_2P|VERB|PLURAL,"prefer");
  TrieAdd("malunt",_3P|VERB|PLURAL,"prefer");
//Bring
  TrieAdd("fero",_1P|VERB|SINGULAR,"bring");
  TrieAdd("fers",_2P|VERB|SINGULAR,"bring");
  TrieAdd("fert",_3P|VERB|SINGULAR,"bring");
  TrieAdd("ferimus",_1P|VERB|PLURAL,"bring");
  TrieAdd("fertis",_2P|VERB|PLURAL,"bring");
  TrieAdd("ferunt",_3P|VERB|PLURAL,"bring");
  TrieAdd("ferebatur",VERB|_3P|IMPERFECT|SINGULAR,"bring");
//To go
  TrieAdd("eo",_1P|VERB|SINGULAR,"go");
  TrieAdd("is",_2P|VERB|SINGULAR,"go");
  TrieAdd("it",_3P|VERB|SINGULAR,"go");
  TrieAdd("imus",_1P|VERB|PLURAL,"go");
  TrieAdd("itis",_2P|VERB|PLURAL,"go");
  TrieAdd("eunt",_3P|VERB|PLURAL,"go");
//Numbers
  AddWordByPrincibleParts("one",ADJECTIVE,"unus","una"); //One
  AddWordByPrincibleParts("two",ADJECTIVE,"duo","duorem"); //Two
  AddWordByPrincibleParts("three",ADJECTIVE,"tres","trium"); //Three
  TrieAdd("quattuor",ADJECTIVE|INDECLINABLE,"four"); //4
  TrieAdd("quinque",ADJECTIVE|INDECLINABLE,"five"); //5
  TrieAdd("sex",ADJECTIVE|INDECLINABLE,"six"); //6
  TrieAdd("septum",ADJECTIVE|INDECLINABLE,"seven"); //7
  TrieAdd("octo",ADJECTIVE|INDECLINABLE,"eight"); //8
  TrieAdd("novem",ADJECTIVE|INDECLINABLE,"nine"); //9
  TrieAdd("decem",ADJECTIVE|INDECLINABLE,"ten"); //10
}
InitDict;

//Use this instead of TrieGet,This will account for -ne -que suffixes
#include "Dict.HC";

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
