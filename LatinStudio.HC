#include "WordForms.HC";
F64 line_height=25;
class CNounForm {
  Bool plural format "$$CB,\"Plural\"$$\n";
  I64 case format "$$LS,D=\"DF_CASES\"$$\n";
};
class CVerbForm {
  I64 tense format "$$LS,D=\"DF_TENSES\"$$\n";
  I64 person format "$$LS,D=\"DF_PERSON\"$$\n";
  Bool passive format "$$CB,\"Active\"$$\n";
  Bool plural format "$$CB,\"Plural\"$$\n";
  Bool subj format "$$CB,\"Subjunctive\"$$\n";
};
I64 DFCaseToFlags(I64 a)  {
  switch(a) {
    case 0:
	return NOMITIVE;
    case:
	return ACCUSATIVE;
    case:
	return DATIVE;
    case:
	return ABLATIVE;
    case:
	return GENITIVE;
    case:
	return VOCATIVE;
  }
  return 0;
}
I64 DFTenseToFlags(I64 a)  {
  switch(a) {
    case 0:
	return PRESENT;
    case:
	return IMPERFECT;
    case:
	return FUTURE;
    case:
	return PERFECT;
    case:
	return PLUPERFECT;
    case:
	return FUTURE|PERFECT;
  }
  return 0;
}
I64 DFPersonToFlags(I64 a)  {
  switch(a) {
    case 0:
	return _1P;
    case :
	return _2P;
    case :
	return _3P;
  }
  return 0;
}
I64 FlagsToDFCase(I64 fl)  {
  I64 a=DefineCnt("DF_CASES"),f;
  while(--a>=0) {
    f=DFCaseToFlags(a);
    if(f&fl==f)
      return a;
  }
  return 0;
}
I64 FlagsToDFTense(I64 fl)  {
  I64 a=DefineCnt("DF_TENSES"),f;
  while(--a>=0) {
    f=DFTenseToFlags(a);
    if(f&fl==f)
      return a;
  }
  return 0;
}
I64 FlagsToDFPerson(I64 fl)  {
  I64 a=DefineCnt("DF_PERSON"),f;
  while(--a>=0) {
    f=DFPersonToFlags(a);
    if(f&fl==f)
      return a;
  }
  return 0;
}
U8 *TranslationMenu(U8 *word) {
  if(!word) return NULL;
  CDoc *doc=DocNew;
  U8 *trans;
  I64 which;
  DocPrint(doc,
	"$$LTPURPLE$$$$TX+CX,\"Translation Menu\"$$$$FD$$\n"
	"  Toggle a translation or$$ BLUE$$$$MU,\"Set a new Translation\",LE=-123$$$$FD$$.\n\n"
	);
  for(which=0;which!=3;which++) {
    trans=WordDBGetTranslation(,word,which);
    if(trans) {
	DocPrint(doc,"$$LTBLUE$$$$MU,\"%Q\",LE=%d$$$$FD$$\n",trans,which);
    }
    Free(trans);
  }
  which=PopUpMenu(doc);
  switch(which) {
    case -123:
      trans=PopUpGetStr("Translation:");
      if(trans)
        WordDBSetTranslation(,word,trans);
      break;
    case 0:
    case 1:
    case 2:
      trans=WordDBGetTranslation(,word,which);
      break;
    default:
      trans=NULL;
      break;
  }
  DocDel(doc);
  return trans;
}
CTrie *ChooseWordForm(CTrie *word) {
  U8 *base_word=GetBaseWord(word->str);
  U8 *ws=GetWordString(base_word),buf[STR_LEN];
  CJson *j=ParseJson(ws),*forms,*form;
  CTrie *have;
  I64 idx2,f,idx;
  CVerbForm verb;
  CNounFormnoun;
  I64 want;
  if(word->flags&VERB) {
    verb.plural=ToBool(word->flags&PLURAL);
    verb.subj=ToBool(word->flags&SUBJUNCTIVE);
    verb.passive=ToBool(word->flags&PASSIVE);
    verb.tense=FlagsToDFTense(word->flags);
    verb.person=FlagsToDFPerson(word->flags);
    PopUpForm(&verb);
    want=(verb.plural*PLURAL)|DFTenseToFlags(verb.tense);
    want|=verb.subj*SUBJUNCTIVE;
    want|=verb.passive*PASSIVE;
    want|=DFPersonToFlags(verb.person);
  }
  if(word->flags&(NOUN|PARTICIPLE|ADJECTIVE)) {
    noun.plural=ToBool(word->flags&PLURAL);
    noun.case=FlagsToDFCase(word->flags);
    PopUpForm(&noun);
    want=(noun.plural*PLURAL)|DFCaseToFlags(noun.case);
  }
  forms=GetJsonMember(j,"forms");
  if(forms) {
    for(idx=0;form=GetJsonMember(forms,StrPrint(buf,"%d",idx));idx++) {
      if(GetJsonMember(form,"form",J_STR)) {
        have=GetWord(GetJsonMember(form,"form")->str);
	if(have) {
	  f=have->flags;
	  if(want&f!=want)
	    goto skip;
	  if(word->flags&(NOUN|VERB|ADJECTIVE|PARTICIPLE)
		!=f&(NOUN|VERB|ADJECTIVE|PARTICIPLE))
	    goto skip;
          if(want&PLURAL^^f&PLURAL)
	    goto skip;
          if(want&SUBJUNCTIVE^^f&SUBJUNCTIVE)
	    goto skip;
          if(want&PASSIVE^^f&PASSIVE)
	    goto skip;
//Account for FUTURE|PERFECT
          if(want&(PERFECT|FUTURE)!=f&(FUTURE|PERFECT))
	    goto skip;
	  goto fin;
	}
skip:;
      }
    }
  }
  have=NULL;
fin:
  Free(ws);
  JsonDel(j);
  Free(base_word);
  return have;
}
U0 Init() {
  DefineLstLoad("DF_CASES","Nomitive\0Accusative\0Dative\0Ablative\0Genitive\0Vocative\0");
  DefineLstLoad("DF_TENSES","Present\0Imperfect\0Future\0Perfect\0Pluperfect\0FutPer\0");
  DefineLstLoad("DF_PERSON","1st_Person\02nd_Person\03rd_Person\0");
}
Init;
U0 LatinEdDrawIt(CTask *t,CDC *dc) {
  CGlAdvance ga;
  U8 *line,buf[STR_LEN],*en,*base;
  I64 idx,y,idx2,len;
  CCursorFind *cf=FramePtr("Latin.cursor_find",t);
  F64 x,w,ox;
  CTrie *word;
  CDoc *doc=FramePtr("Latin.doc",t),*odoc=doc;
  CDC *dummy=DCNew(1,1);
  if(!doc)
    return;
  line=DocSave(doc,&x);
  doc=DocNew;
  DocLoad(doc,line,x);
  Free(line);
  dc->color=BLACK;
  I64 oline=FramePtr("Latin.top",t),line2;
  for(line2=oline;line2<=(t->win_bottom-t->win_top)*8/line_height+oline-1;++line2) {
    if (DocGoToLine(doc,line2) && doc->cur_entry->type_u8==DOCT_TEXT)
      line=MStrPrint("%s ",doc->cur_entry->tag); //Add a end of line space
    else //We set DOCF_PLAIN_TEXT,so assume a newline
      line=StrNew(" ");
    y=(line2-oline)*line_height;
    if(cf) {
      if(y<=cf->y<=y+line_height) {
	TTF_RenderText(dummy,0,y,line,,,odoc->x-idx2,cf);
	cf->user_data=line2-1;
	FramePtrDel("Latin.cursor_find",t);
	cf=NULL;
      }
    }
    x=0;
    for(idx2=0;line[idx2];) {
      en=SkipWhitespace(line+idx2);
      if(en!=line+idx2) {
        MemCpy(buf,line+idx2,len=en-&line[idx2]);
        buf[len]=0;
        if(odoc->y==line2-1) {
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        } else
	  x+=TTF_RenderText(dc,x,y,buf);
        idx2=en-line;
      } else if(Bt(char_bmp_alpha_numeric,line[idx2])){
        len=0;
        while(line[len+idx2]&&Bt(char_bmp_alpha_numeric,line[len+idx2]))
	  ++len;
        MemCpy(buf,line+idx2,len);
        buf[len]=0;
        if(word=GetWord(buf)) {
	  dc->color=GREEN;
	  ox=x;
	  if(odoc->y==line2-1)
	    x+=DrawSexyWord(dc,16.,x,y,word,buf,odoc->x-idx2);
	  else
	    x+=DrawSexyWord(dc,16.,x,y,word,buf);
	  w=DrawWordInfo(dc,0,0,word,TRUE,buf);
	  DrawWordInfo(dc,(x-ox)/2.+ox-w/2.,y+16.,word,FALSE,buf);
	  base=GetBaseWord(word->str);
	  if(base)
	     word=GetWord(base);
	  else
	    word=NULL;
	  if(word&&word->translation) {
	    dc->color=BLACK;
	    w=TTF_RenderText(dummy,0,y,word->translation);
	    TTF_RenderText(dc,ox,y+24,word->translation);
	    if(x<ox+w)
	      x=ox+w;
	  }
	  
        } else {
	  dc->color=LTRED;
	  if(odoc->y==line2-1)
	    x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
	  else
	    x+=TTF_RenderText(dc,x,y,buf);
        }
        idx2+=len;
      } else {
        len=1;
        buf[0]=line[idx2];
        buf[len]=0;
        dc->color=BLACK;
        if(odoc->y==line2-1)
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        else
	  x+=TTF_RenderText(dc,x,y,buf);
	idx2+=len;
      }
    }
    Free(line);
  }
  DCDel(dummy);
  DocDel(doc);
}
U0 LatinEd(U8 *file) {
  CDoc *doc=DocRead(file,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
  DocClear;
  I64 m,x,y,ww,wh,scroll,lc,len;
  I64 oldz=ms.pos.z;
  CTrie *trie;
  U8 *line,buf[STR_LEN];
  FramePtrAdd("Latin.top",1);
  FramePtrAdd("Latin.doc",doc);
  CCursorFind cf;
  Fs->draw_it=&LatinEdDrawIt;
  while(TRUE) {
    ww=(Fs->win_right-Fs->win_left)*8/line_height;
    wh=(Fs->win_bottom-Fs->win_top)*8/line_height;
    x=doc->x,y=doc->y;
    DocBottom(doc);
    lc=doc->y;
    doc->x=x,doc->y=y;
    DocRecalc(doc,RECALCt_FIND_CURSOR);
    if(ms.pos.z!=oldz&&0) {
      scroll=FramePtr("Latin.top");
      scroll=ClampI64(scroll+ms.pos.z-oldz,1,MaxI64(1,lc-wh));
      FramePtrSet("Latin.top",scroll);
      oldz=ms.pos.z;
    }
    while(m=ScanMsg(&x,&y)) {
      if(m==MSG_MS_L_DOWN) {
        cf.x=x;
        cf.y=y;
        cf.found_ch_idx=doc->x;
        cf.user_data=doc->y;
        FramePtrAdd("Latin.cursor_find",&cf);
        Refresh;
        doc->y=cf.user_data;
        doc->x=cf.found_ch_idx;
        DocRecalc(doc,RECALCt_FIND_CURSOR);
      }
      if(m==MSG_MS_R_DOWN) {
        cf.x=x;
        cf.y=y;
        cf.found_ch_idx=doc->x;
        cf.user_data=doc->y;
        FramePtrAdd("Latin.cursor_find",&cf);
        Refresh;
        doc->y=cf.user_data;
        doc->x=cf.found_ch_idx;
        DocRecalc(doc,RECALCt_FIND_CURSOR);
//Open word form
        if(doc->cur_entry->type_u8==DOCT_TEXT) {
	  x=doc->x;
	  line=doc->cur_entry->tag;
	  if(Bt(char_bmp_alpha_numeric,line[x])) {
	    while(x>=0&&Bt(char_bmp_alpha_numeric,line[x])) {
	      --x;
	    }
	    ++x;
	    len=0;
	    while(line[x+len]&&Bt(char_bmp_alpha_numeric,line[x+len])) {
	      buf[len]=line[x+len];
	      ++len;
	    }
	    buf[len]=0;
	    if(trie=GetWord(buf)) {
	      trie=ChooseWordForm(trie);
	      if(trie) {
	        doc->x=x;
	        DocRecalc(doc,RECALCt_FIND_CURSOR);
//Delete word
	        while(--len>=0) {
		  EdCharDel(doc);
	        }
	        DocPrint(doc,"%s",trie->str);
	      }
	    }
	  }
        }
      }
      if(m==MSG_KEY_DOWN) {
        if(x==CH_ESC)
	  goto fin;
        else if(x==CH_CTRLT) {
	  if(doc->cur_entry->type_u8==DOCT_TEXT) {
	    x=doc->x;
	    line=doc->cur_entry->tag;
	    if(Bt(char_bmp_alpha_numeric,line[x])) {
	      while(x>=0&&Bt(char_bmp_alpha_numeric,line[x])) {
	        --x;
	      }
	      ++x;
	      len=0;
	      while(line[x+len]&&Bt(char_bmp_alpha_numeric,line[x+len])) {
	        buf[len]=line[x+len];
	        ++len;
	      }
	      buf[len]=0;
	      if(line=TranslationMenu(buf)) {
	        doc->x=x;
	        DocRecalc(doc,RECALCt_FIND_CURSOR);
	        while(--len>=0) {
		  EdCharDel(doc);
	        }
	        DocPrint(doc,"%s",line);
		Free(line);
	      }
	    }
	  }
        } else if(!x) {
	  if(y.u8[0]==SC_PAGE_DOWN) {
	    x=wh;
	    while(--x>=0)
	      EdLineDown(doc);
	  }
	  if(y.u8[0]==SC_PAGE_UP) {
	    x=wh;
	    while(--x>=0)
	      EdLineUp(doc);
	  }
	  if(y.u8[0]==SC_CURSOR_LEFT) {
	    EdCursorLeft(doc,y);
	  }
	  if(y.u8[0]==SC_CURSOR_RIGHT) 
	    EdCursorRight(doc,y);
	  if(y.u8[0]==SC_CURSOR_UP)
	    EdLineUp(doc,y);
	  if(y.u8[0]==SC_CURSOR_DOWN)
	    EdLineDown(doc,y);
        } else if(x==CH_BACKSPACE) {
	  EdCursorLeft(doc);
	  EdCharDel(doc);
        } else if(Bt(char_bmp_displayable,x&0xffff)) {
	  EdCharIns(x,y,doc);
        } else if(x=='\n') {
	  EdCharIns(x,y,doc);
        }
      }
    }
    scroll=FramePtr("Latin.top");
    ++doc->y;
    if(scroll>doc->y||doc->y>=scroll+wh) {
      if(doc->y<scroll)
        scroll=doc->y;
      else
        scroll=MaxI64(1,doc->y-wh+1);
      FramePtrSet("Latin.top",scroll);
    }
    --doc->y;
    Refresh;
  }
fin:;
  FramePtrDel("Latin.doc");
  FramePtrDel("Latin.top");
  DocWrite(doc);
  DocDel(doc);
}
LatinEd("/Ass.DD");