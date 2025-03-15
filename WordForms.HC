#include "Visual.HC";
I64 class CEntDim {
  I32 w,h;
};
CEntDim EntDimMax(CEntDim a,CEntDim b) {
  return MaxI64(a.w,b.w)|MaxI64(a.h,b.h)<<32;
}
CEntDim WordTableEntry(CDC *dc,I64 cx,I64 cy,I64Set *f,I64 flags) {
  I64 idx,w,mw=0;
  CTrie *trie;
  I64Set *done=NULL;
  CDC *dumb=DCNew(1,1);
  I64 ocy=cy;
  CTrie dumbt;
  for(idx=0;idx!=f->cnt;idx++) {
    if(trie=GetWord(f->body[idx])) {
      while(trie) {
        if(trie->flags&flags==flags) {
	  if(trie->flags&VERB&&(flags&IMPERATIVE^^trie->flags&IMPERATIVE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&flags&IMPERATIVE)
	    goto pass;
	  if(trie->flags&VERB&&(flags&PASSIVE^^trie->flags&PASSIVE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&(flags&SUBJUNCTIVE^^trie->flags&SUBJUNCTIVE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&(flags&INFINITIVE^^trie->flags&INFINITIVE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&(flags&FUTURE^^trie->flags&FUTURE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&(flags&PARTICIPLE^^trie->flags&PARTICIPLE)) {
	     goto skip;
	  }
	  if(trie->flags&VERB&&(flags&PERFECT^^trie->flags&PERFECT)) {
	     goto skip;
	  }
pass:;
	  MemCpy(&dumbt,trie,sizeof(CTrie));
	  dumbt.flags=flags|NOUN|VERB; //Only use relevant flags
	  dc->color=LTGREEN;
	  w=DrawSexyWord(dumb,14,cx,cy,&dumbt,trie->str);
	  DrawSexyWord(dc,14,cx-w/2,cy,&dumbt,trie->str);
	  mw=MaxI64(mw,w+10);
	  w=DrawWordInfo(dumb,cx,cy,&dumbt,TRUE,trie->str);
  	  DrawWordInfo(dc,cx-w/2,cy+12,&dumbt,FALSE,trie->str);
	  mw=MaxI64(mw,w+10);
	  cy+=24;
	  goto next;
        }
skip:;
        trie=trie->next;
      }
next:;
    }
  }
  DCDel(dumb);
  return mw|(cy-ocy+12)<<32;
}
CDC *WordTable(U8 *word) {
  U8 *base=GetBaseWord(word),buf[STR_LEN];
  if(!base) return;
  U8 *word_str=GetWordString(base),*text;
  CEntDim ent_max=0,tmp;
  I64 idx,idx2;
  I64Set *f=NULL;
  CJson *j=ParseJson(word_str),*forms,*form;
  CTrie *trie;
  CDC*dummy=DCNew(I32_MAX,I32_MAX,Fs,TRUE),*dc;
  I64 ox=I32_MAX/2,oy=I32_MAX/2;
  I64 x,y,x2,y2,use_flags;
  if(!j) goto en;
  dummy->flags|=DCF_RECORD_EXTENTS;
  dummy->min_x=I32_MAX/2;
  dummy->min_y=I32_MAX/2;
  dummy->max_x=I32_MAX/2;
  dummy->max_y=I32_MAX/2;
  forms=GetJsonMember(j,"forms");
  if(forms) {
    for(idx=0;form=GetJsonMember(forms,StrPrint(buf,"%d",idx));idx++) {
      if(GetJsonMember(form,"form",J_STR)) {
        text=GetJsonMember(form,"form")->str;
        if(f)
	  for(idx2=0;idx2!=f->cnt;idx2++) {
	    if(!StrCmp(text,f->body[idx2]))
	      goto skip;
	  }
        f=I64SetAdd(f,text);
skip:;
      }
    }
  }
  trie=GetWord(base);
  if(f)
    for(idx=0;idx!=2;idx++) {
      if(trie->flags&(CONJUGATION1|CONJUGATION2|CONJUGATION3|CONJUGATION4)) {
        static I64 conj_x[6]={
        SINGULAR|_1P,
	      SINGULAR|_2P,
	      SINGULAR|_3P,
	      PLURAL|_1P,
	      PLURAL|_2P,
	      PLURAL|_3P
	      };
        static I64 conj_y[9+6+2]={
        ACTIVE|PRESENT,
	      ACTIVE|IMPERFECT,
	      ACTIVE|FUTURE,
	      ACTIVE|PERFECT,
	      ACTIVE|PLUPERFECT,
	      ACTIVE|FUTURE|PERFECT,
	      PASSIVE|PRESENT,
	      IMPERFECT|PASSIVE,
	      PASSIVE|FUTURE,
//
	      SUBJUNCTIVE|ACTIVE|PRESENT,
	      SUBJUNCTIVE|ACTIVE|IMPERFECT,
	      SUBJUNCTIVE|ACTIVE|PERFECT,
	      SUBJUNCTIVE|ACTIVE|PLUPERFECT,
	      SUBJUNCTIVE|PASSIVE|PRESENT,
	      SUBJUNCTIVE|IMPERFECT|PASSIVE,
//
	      IMPERATIVE|ACTIVE,
	      IMPERATIVE|PASSIVE,

	      };

        static U8 *conj_y_labels[9+6+2]={
        "Act.Ind. Pres",
	      "Act.Ind. Imper",
	      "Act.Ind. Fur",
	      "Act.Ind. Per",
	      "Act.Ind. Plu",
	      "Act.Ind. FutPer",
	      "Pass.Ind. Pres",
	      "Pass.Ind. Imp",
	      "Pass.Ind. Fut",

	      "Act.Subj. Pres",
	      "Act.Subj. Imper",
	      "Act.Subj. Per",
	      "Act.Subj. Plu",
	      "Pass.Subj. Pres",
	      "Pass.Subj. Imp",

	      "Act. Imper",
	      "Pass. Imper",
	      };

        y2=oy-15;
	      dummy->color=LTGREEN;
        GrTextBox3(dummy,ox+0*ent_max.w,y2,0,"Sing. 1P");
        GrTextBox3(dummy,ox+1*ent_max.w,y2,0,"Sing. 2P");
        GrTextBox3(dummy,ox+2*ent_max.w,y2,0,"Sing. 3P");
        GrTextBox3(dummy,ox+3*ent_max.w,y2,0,"Plu. 1P");
        GrTextBox3(dummy,ox+4*ent_max.w,y2,0,"Plu. 2P");
        GrTextBox3(dummy,ox+5*ent_max.w,y2,0,"Plu. 3P");
        for(x2=0;x2!=6;x2++) {
	  for(y2=0;y2!=9+6+2;y2++) {
	    x=ox+ent_max.w*x2,y=oy+ent_max.h*y2;
	    dummy->color=LTRED;
	    GrRect(dummy,x,y,ent_max.w,ent_max.h);
	    if(x2&1)
	      dummy->color=YELLOW;
	    else
	      dummy->color=WHITE;

	    GrRect(dummy,x+5,y+5,ent_max.w-10,ent_max.h-10);

	    use_flags=conj_x[x2]|conj_y[y2];
	    if(y2>=6+9)
		use_flags&=~(_1P|_2P|_3P);
	    ent_max=EntDimMax(ent_max,WordTableEntry(dummy,x+ent_max.w/2,y,f,use_flags));

	    if(x2==0) {
	      dummy->color=LTGREEN;
	      GrTextBox3(dummy,x-StrLen(conj_y_labels[y2])*8-4,y,0,conj_y_labels[y2]);
	    }

	  }
        }
      } else if(trie->flags&(DECLENSION1|DECLENSION2|DECLENSION3|DECLENSION4|DECLENSION5)) {
        static I64 declen_flags[2*6]={
        SINGULAR|NOMITIVE,PLURAL|NOMITIVE,
	      SINGULAR|ACCUSATIVE,PLURAL|ACCUSATIVE,
	      SINGULAR|GENITIVE,PLURAL|GENITIVE,
	      SINGULAR|DATIVE,PLURAL|DATIVE,
	      SINGULAR|ABLATIVE,PLURAL|ABLATIVE,
	      SINGULAR|VOCATIVE,PLURAL|VOCATIVE
	      };
        static U8 *declen_labels0[2]={
        "Singular","Plural"
	      };
        static U8 *declen_labels1[6]={
        "Nomitive","Accusative","Genitive","Dative","Ablative","Vocative",
	      };
        for(idx2=0;idx2!=2*6;idx2++) {
	  x=ox+ent_max.w*(idx2&1),y=oy+ent_max.h*(idx2/2);
	  dummy->color=LTRED;
	  GrRect(dummy,x,y,ent_max.w,ent_max.h);
	  if(idx2/2==0) {
	    dummy->color=LTGREEN;
	    GrTextBox3(dummy,x+5,y-16,0,declen_labels0[idx2]);
	  }
	  if(idx2&1==0) {
	    dummy->color=LTGREEN;
	    GrTextBox3(dummy,x-StrLen(declen_labels1[idx2/2])*8-4,y,0,declen_labels1[idx2/2]);
	  }
	  if(idx2&1)
	    dummy->color=YELLOW;
	  else
	    dummy->color=WHITE;
	  GrRect(dummy,x+5,y+5,ent_max.w-10,ent_max.h-10);
	  ent_max=EntDimMax(ent_max,WordTableEntry(dummy,x+ent_max.w/2,y,f,declen_flags[idx2]));  
        }
      }
      if(!idx) {
	dc=DCNew(dummy->max_x-dummy->min_x+1,dummy->max_y-dummy->min_y+1);
        DCFill(dc,TRANSPARENT);
        ox=I32_MAX/2-dummy->min_x;
        oy=I32_MAX/2-dummy->min_y;
        DCDel(dummy);
        dummy=dc;
      }
    }

    en:;
  Free(f);
  JsonDel(j);
  Free(word_str);
  Free(base);
  return dc;
}
U0 DocWordTable(CDoc *doc,U8 *word) {
  CDC *dc2;
  U8 *tmp;
  dc2=WordTable(word);
  DocSprite(doc,tmp=DC2Sprite(dc2));
  I64 h=dc2->height;
  Free(tmp);
  DCDel(dc2);
  while((h-=8)>=0)
    "\n";
  "\n";
}
DocClear;
DocMax;
DocWordTable(DocPut,"velox");
DocWordTable(DocPut,"amo");
DocWordTable(DocPut,"video");
DocWordTable(DocPut,"tego");
DocWordTable(DocPut,"audio");
DocWordTable(DocPut,"puella");
DocWordTable(DocPut,"ager");
DocWordTable(DocPut,"rex");
DocWordTable(DocPut,"manus");
DocWordTable(DocPut,"res");