#include "WordForms.HC";
#include "DumbDoc.HC";
F64 line_height=25;
CDC *ed_scrn=DCNew(GR_WIDTH,GR_HEIGHT);
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
U8 *CurrentSentence(CDDoc *doc,CD2I64 *start=NULL,CD2I64 *end=NULL) {
  U8 *ret;
  I64 c;
  I64 oldc,oldl,cnt;
  oldc=doc->x,oldl=doc->y;
  doc->x=oldc,doc->y=oldl;
  CDoc *rd=DocNew;
 
  while(c=DDocCurU32(doc)) {
    if(c=='.') {
      DDocRight(doc);
      break;
    }
    DDocLeft(doc);
    if(doc->x<=0&&doc->y<=0)
	break;
  }
  while(Bt(char_bmp_white_space,c=DDocCurU32(doc))) {
    if(!c) break;
    DDocRight(doc);
  }
  if(start) {
    start->x=doc->x;
    start->y=doc->y;
  }
  while(c=DDocCurU32(doc)) {
    if(c=='.'||c<0)
      break;
    DocPrint(rd,"%c",c);
    DDocRight(doc);
  }
  if(c=='.')
    DDocRight(doc);
  if(end) {
    end->x=doc->x;
    end->y=doc->y;
  }
  doc->x=oldc,doc->y=oldl;

  ret=DocSave(rd);
  DocDel(rd);
  return ret;
}
U0 GrammarASTDump0(CDoc *doc,AST *ast,U8 **toks,CTrie **forms,I64 *depths,I64 depth=0) {
  if(!ast) return;
  I64 i;
  I64Set *set;
  if(ast->word)
    forms[ast->word_idx]=ast->word;
  if(ast->error) {
    DocPrint(doc,"$$TR-C,\"%Q\"$$$$ID,2$$\n$$RED$$",ast->error);
    for(i=ast->start;i!=ast->end;++i) {
      DocPrint(doc,"%Q ",toks[i]);
      ++depths[i];
    }
    DocPrint(doc,"$$FD$$$$ID,-2$$\n");
    ++depth;
  }
  GrammarASTDump0(doc,ast->base_expression,toks,forms,depths,depth);
  if(set=ast->args) {
    i=set->cnt;
    while(--i>=0) {
      if(ast!=set->body[i])
        GrammarASTDump0(doc,set->body[i],toks,forms,depths,depth);
    }
  }
}
U0 ClearMarkings(CDDoc *doc,I64 x,I64 y,I64 x2,I64 y2) {
  CDDLine *ln;
  I64 cnt,oy=y,sx,ex;
  I64Set *markers;
  CDDMarker *mark;
  do {
    ln=doc->lines->body[y];
    if(markers=ln->markers) {
again:;
      cnt=markers->cnt;
      while(--cnt>=0) {
        mark=markers->body[cnt];
	if(y==oy&&y==y2)
	  sx=x,ex=x2;
	else if(y==oy)
	  sx=x,ex=I64_MAX;
	else if(y==y2)
	  sx=0,ex=x2;
        else
	  sx=0,ex=I64_MAX;
        if(sx<=mark->offset<ex) {
	  I64SetRem(markers,mark);
	  goto again;
        }
      }
    }
  } while(++y<y2);
}
U0 GrammarCheckAtSentence(CDDoc *doc,Bool popup=TRUE) {
  CD2I64 sentence_start;
  I64 ox=doc->x,oy=doc->y;
  U8 *sent=CurrentSentence(doc,&sentence_start);
  if(!sent) return;
  I64 color,lastx,lasty;
  U8 *st=sent,*tmp,*line_ptr,*oline_ptr,*tmp2;
  U8 **toks=TokenizeSentence(st,&st,TRUE,TRUE);
  I64 tcnt=0,*error_depths,i;
  CDC *dc;
  CDDMarker *mark;
  while(tmp=toks[tcnt])
    tcnt++;

  AST *ast=ParseSentenceJoin(tcnt,toks);
  if(!ast) {
    FramePtrAdd("GrammarCheck",1);
    ast=ParseSentenceJoin(tcnt,toks);
  }
  CTrie **forms=CAlloc(8*tcnt);
  CDoc *errs=DocNew;
  if(ast) {
    dc=DrawSentence(ast,tcnt,toks);
    error_depths=CAlloc(8*tcnt);
    NumberAST(ast);
    GrammarASTDump0(errs,ast,toks,forms,error_depths);
    DocTop(errs);
    DocPrint(errs,"$$TX+CX,\"Grammar Check\"$$\n\n\n\n\n\n");
    dc=DrawSentence(ast,tcnt,toks);
    DocSprite(errs,DC2Sprite(dc));
    i=dc->height/8;
    DCDel(dc);
    while(--i>=0)
      DocPrint(errs,"\n");

    doc->x=sentence_start.x;
    doc->y=sentence_start.y;
    tcnt=0;
    while(tmp=toks[tcnt]) {
      mark=NULL;
      DDFind(doc,tmp);
      lastx=doc->x,lasty=doc->y;
 //Skip word
      tmp2=tmp;
      while(ReadUTF8(tmp2,&tmp2))
        DDocRight(doc);
  
      ClearMarkings(doc,lastx,lasty,doc->x,doc->y);
      if(error_depths[tcnt]) {
        switch(error_depths[tcnt]) {
	  case 1:
	    color=LTRED;
	    break;
	  case :
	    color=LTPURPLE;
	    break;
	  case :
	    color=RED;
	    break;
	  case :
	    color=PURPLE;
	    break;
	  default:
	    color=YELLOW;
	    break;
        }
        SwapI64(&doc->x,&lastx);
        mark=DDMarkerNew(doc,StrLen(tmp),color,"grammar"); //TODO message
        SwapI64(&doc->x,&lastx);
      }
      if(!mark&&forms[tcnt]) {
        SwapI64(&doc->x,&lastx);
        mark=DDMarkerNew(doc,StrLen(tmp),-1,"");
        SwapI64(&doc->x,&lastx);
      }
      if(mark) {
	mark->word=forms[tcnt];
      }
      ++tcnt;
    }

    tcnt=0;
    while(tmp=toks[tcnt]) {
      switch(error_depths[tcnt]) {
        case 0:
	  DocPrint(errs,"$$BLACK$$%Q $$FD$$",tmp);
	  break;
        case :
	  DocPrint(errs,"$$LTRED$$%Q $$FD$$",tmp);
	  break;
        case :
	  DocPrint(errs,"$$LTPURPLE$$%Q $$FD$$",tmp);
	  break;
        case :
	  DocPrint(errs,"$$RED$$%Q $$FD$$",tmp);
	  break;
        case :
	  DocPrint(errs,"$$PURPLE$$%Q $$FD$$",tmp);
	  break;
        default:
	  DocPrint(errs,"$$YELLOW$$%Q $$FD$$",tmp);
	  break;
      }
      tcnt++;
    }
    DocPrint(errs,"\n\n");;
    DocTop(errs);
    if(popup)
      PopUp(tmp=MStrPrint("DocEd(%d);;",errs),Fs);
    Free(tmp);
    Free(error_depths);

  
  }
  Free(forms);
  tcnt=0;
  while(toks[tcnt])
    Free(toks[tcnt++]);
  Free(toks);
  ASTDel(ast);

  FramePtrDel("GrammarCheck");
  Free(sent);
  DocDel(errs);
}
U0 GrammarCheckBG(CDDoc *doc,I64 top,I64 bottom) {
  I64 old_x=doc->x,old_y=doc->y;
  CD2I64 end,old_end;
  doc->x=0,doc->y=0;
  old_end.x=0,old_end.y=top;
  end.x=0;
  end.y=top;
  CDDLine *ln;
again:;
  do {
    old_end.x=end.x;
    old_end.y=end.y;
    doc->x=end.x;
    doc->y=end.y;
    ln=doc->lines->body[doc->y];
    if(!ln->tainted) {
      if(++doc->y<doc->lines->cnt) {
        end.x=0;
        end.y=doc->y;
	if(end.y>=bottom)
	  break;
        goto again;
      } else
        break;
    } else {
     ln->tainted=FALSE;
    }
    Free(CurrentSentence(doc,NULL,&end));
    doc->x=old_end.x;
    doc->y=old_end.y;
    GrammarCheckAtSentence(doc,FALSE);
    if(end.y>=bottom)
	break;
  } while(end.x!=old_end.x||end.y!=old_end.y);
  doc->x=old_x;
  doc->y=old_y;
}
I64 MarkerSort(CDDMarker *a,CDDMarker *b) {
  return a->offset-b->offset;
}
CDDMarker *MarkerForWord0(I64Set *set,I64 st,I64 en) {
  if(!set) return NULL;
  I64 cnt=set->cnt;
  CDDMarker *mark;
  while(--cnt>=0) {
    mark=set->body[cnt];
    if(st<=mark->offset<en)
	return mark; //TODO closest
  }
  return NULL;
}
U0 LatinEdDrawIt(CTask *t,CDC *dc) {
  CGlAdvance ga;
  U8 *line,buf[STR_LEN],*en,*base;
  I64 idx,y,idx2,len,cp;
  CCursorFind *cf=FramePtr("Latin.cursor_find",t);
  F64 x,w,ox;
  CTrie *word;
  CDDoc *doc=FramePtr("Latin.doc",t),*odoc=doc;
  CDDLine *ddline;
  I64Set *markers;
  CDDMarker *mark;
  I64 start,end;
  CDC *dummy=DCNew(1,1);
  if(!doc)
    return;
  dc->color=BLACK;
  I64 oline=FramePtr("Latin.top",t),line2;
  FramePtrDel("Latin.cursor_find",t);
  for(line2=oline;line2<=(t->win_bottom-t->win_top)*8/line_height+oline-1;++line2) {
    if(line2>=doc->lines->cnt)
      break;
    base=DDocSave(doc,line2,line2+1);
    line=MStrPrint("%s ",base);
    Free(base);
    y=(line2-oline)*line_height;
    if(cf) {
      if(y<=cf->y<=y+line_height) {
        cf->user_data=line2;
      }
    }
    ddline=doc->lines->body[line2];
//Draw line markers
    if(markers=ddline->markers) {
      QSortI64(markers->body,markers->cnt,&MarkerSort);
    }
//Draw Text
    x=0;
    for(idx2=0;line[idx2];) {
      start=idx2;
      en=SkipWhitespace(line+idx2);
      if(en!=line+idx2) {
        MemCpy(buf,line+idx2,len=en-&line[idx2]);
        buf[len]=0;
        if(odoc->y==line2) {
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        } else
	  x+=TTF_RenderText(dc,x,y,buf,,,,cf);
        idx2=en-line;
      } else if(Bt(char_bmp_alpha_numeric,line[idx2])){
        len=0;
        while(line[len+idx2]&&Bt(char_bmp_alpha_numeric,line[len+idx2]))
	  ++len;
        MemCpy(buf,line+idx2,len);
        buf[len]=0;
        if(cf&&cf->user_data==line2) {
	  cf->found_ch_offset=idx2;
	  TTF_RenderText(dummy,x,y,buf,,,,cf);
        }
        if(word=GetWord(buf)) {
	  if(mark=MarkerForWord0(markers,start,start+1))
	    if(mark->word)
	      word=mark->word;
	  dc->color=GREEN;
	  ox=x;
	  if(odoc->y==line2)
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
invalid:
	  dc->color=LTRED;
	  if(odoc->y==line2)
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
        if(odoc->y==line2)
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        else
	  x+=TTF_RenderText(dc,x,y,buf);
        idx2+=len;
      }
      end=idx2;
      if(mark=MarkerForWord0(markers,start,start+1)) {
	if(mark->color>=0) {
	  dc->color=mark->color;
	  GrRect(dc,ox,y+17,x-ox,4); //TODO font size
	}
      }
    }
    Free(line);
  }
  DCDel(dummy);
  gc_enable=TRUE;
}
U0 CopyScrn(CTask*,CDC *dc) {
  GrBlot(dc,0,0,ed_scrn);
}
U0 LatinEd(U8 *file) {
  U8 *line,buf[STR_LEN];
  CDC *empty=DCNew(1,1),*buffer=DCNew(GR_WIDTH,GR_HEIGHT);
  CDDoc *doc;
  DocClear;
  I64 m,x,y,ww,wh,scroll,lc,len;
  I64 oldz=ms.pos.z;
  F64 next_tS=tS+3.;
  CTrie *trie;
  if(FileFind(file)) {
    doc=DDocLoad(line=FileRead(file));
    Free(line);
  } else
    doc=DDocNew;
  FramePtrAdd("Latin.top",0);
  FramePtrAdd("Latin.doc",doc);
  CCursorFind cf;
  Fs->draw_it=&CopyScrn;
  while(TRUE) {
    ww=(Fs->win_right-Fs->win_left)*8/line_height;
    wh=(Fs->win_bottom-Fs->win_top)*8/line_height;
    if(ms.pos.z!=oldz&&0) {
      scroll=FramePtr("Latin.top");
      scroll=ClampI64(scroll+ms.pos.z-oldz,0,MaxI64(0,lc-wh));
      FramePtrSet("Latin.top",scroll);
      oldz=ms.pos.z;
    }
    while(m=ScanMsg(&x,&y)) {
      if(m==MSG_MS_L_DOWN) {
        cf.x=x;
        cf.y=y;
        cf.found_ch_idx=doc->x;
        cf.user_data=doc->y;
        cf.best_dist=I16_MAX*I16_MAX;
        FramePtrAdd("Latin.cursor_find",&cf);
//Sometimes winmgr likes to stop showing after alot of lag
        LatinEdDrawIt(Fs,empty);
        doc->y=cf.user_data;
        doc->x=cf.found_ch_idx;
      }

      if(m==MSG_KEY_DOWN&&x==CH_CTRLF) {
	m=0;
	goto word_form;
      }
      if(m==MSG_KEY_DOWN&&x==CH_CTRLC) {
	GrammarCheckAtSentence(doc);
	m=0;
      }
      if(m==MSG_MS_R_DOWN) {
        cf.x=x;
        cf.y=y;
        cf.found_ch_idx=doc->x;
        cf.user_data=doc->y;
        FramePtrAdd("Latin.cursor_find",&cf);
//Sometimes winmgr likes to stop showing after alot of lag
        LatinEdDrawIt(Fs,empty);
        doc->y=cf.user_data;
        doc->x=cf.found_ch_idx;
word_form:
//Open word form
	  x=doc->x;
          line=DDocSave(doc,doc->y,doc->y+1);
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
	        doc->x=x+len;
//Delete word
	        while(--len>=0) {
		  DDocBackspace(doc);
	        }
	        DDocPrint(doc,"%s",trie->str);
	      }
	    }
	  }
	  Free(line);
        }
      if(m==MSG_KEY_DOWN) {
        if(x==CH_ESC)
	  goto fin;
        else if(x==CH_CTRLT) {
	    x=doc->x;
            line=DDocSave(doc,doc->y,doc->y+1);
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
	        doc->x=x+len;
	        while(--len>=0) {
		  DDocBackspace(doc);
	        }
	        DDocPrint(doc,"%s",line);
		Free(line);
	      }
	    }
        } else if(!x) {
	  if(y.u8[0]==SC_PAGE_DOWN) {
	    x=wh;
	    while(--x>=0)
	      DDocDown(doc);
	  }
	  if(y.u8[0]==SC_PAGE_UP) {
	    x=wh;
	    while(--x>=0)
	      DDocUp(doc);
	  }
	  if(y.u8[0]==SC_CURSOR_LEFT) {
	    DDocLeft(doc,y);
	  }
	  if(y.u8[0]==SC_CURSOR_RIGHT) 
	    DDocRight(doc,y);
	  if(y.u8[0]==SC_CURSOR_UP)
	    DDocUp(doc,y);
	  if(y.u8[0]==SC_CURSOR_DOWN)
	    DDocDown(doc,y);
        } else if(x==CH_BACKSPACE) {
	  DDocBackspace(doc);
        } else if(Bt(char_bmp_displayable,x&0xffff)) {
	  DDocInsChr(doc,x);
        } else if(x=='\n') {
	  DDocInsChr(doc,x);
        }
      }
    }
//Sometimes winmgr likes to stop showing after alot of lag
    DCFill(buffer,TRANSPARENT);
    LatinEdDrawIt(Fs,buffer);
    DCFill(ed_scrn);
    GrBlot(ed_scrn,0,0,buffer);
    Refresh;
    scroll=FramePtr("Latin.top");
    if(scroll>doc->y||doc->y>=scroll+wh) {
      if(doc->y<scroll)
        scroll=doc->y;
      else
        scroll=MaxI64(1,doc->y-wh+1);
      FramePtrSet("Latin.top",scroll);
    }
    if(tS>next_tS) {
      GrammarCheckBG(doc,scroll,scroll+wh);
      next_tS=tS+3.;
    }
  }
fin:;
  line=DDocSave(doc);
  FileWrite(file,line,StrLen(line));
  Free(line);
  FramePtrDel("Latin.doc");
  FramePtrDel("Latin.top");
  Fs->draw_it=0;
  Refresh;
  DCDel(empty);
  DCDel(buffer);
}
LatinEd("/Ass.DD");