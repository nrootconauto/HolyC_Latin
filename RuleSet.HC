#include "GrammarAST.HC"
#define LIMIT_FP "GenCap"
#define CNT_FP "GenCnt"
#define RESULTS_FP "Results"
CTask *grammar_task=Fs;
class CRule {
  U8 name[STR_LEN]; //Rule name or word name
  I64 raw_type;
  U8 *validate_fun; //CallExtStr HasForm Bool Fun(I64 argc,CAST **argc);
  U8 *flags_fun; //CallExtStr HasForm Bool Fun(...); Sets the flags of the node
  I64Set *made_from;
//add_to_member is a list of member types (AST_xxx) to add made_from's too 
//NULL for default
  I64Set *member_types;
  I64 main_item_idx;
  I64 is_word;
  I64 word_flags; //Flags to match
  F64 weight; //.5 by default
};

I64 MemberNameToI64(U8 *str) {
  if(!StrCmp(str,"NOUN"))
    return AST_NOUN;
  else if(!StrCmp(str,"VERB"))
    return AST_VERB;
  else if(!StrCmp(str,"CONJUNCTION"))
    return AST_CONJUNCTION;
  else if(!StrCmp(str,"OF"))
    return AST_OF;
  else if(!StrCmp(str,"WHERE"))
    return AST_WHERE;
  else if(!StrCmp(str,"ADJECTIVE"))
    return AST_ADJECTIVE;
  else if(!StrCmp(str,"INFINITIVE"))
    return AST_INFINITIVE;
  else if(!StrCmp(str,"MEASURE"))
    return AST_MEASURE;
  else if(!StrCmp(str,"ADVERB"))
    return AST_ADVERB;
  else if(!StrCmp(str,"CLAUSE"))
    return AST_INDIRECT_CLAUSE;
  else if(!StrCmp(str,"COMPARE"))
    return AST_COMPARSION;
  else if(!StrCmp(str,"QUESTION"))
    return AST_QUESTION;
  else
    return -1;
}
#define CASE_MASK (NOMITIVE|ACCUSATIVE|ABLATIVE|DATIVE|GENITIVE)
#define NUMBER_MASK (PLURAL)
I64 FlagsSingle(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=0;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN)
      or|=ast->flags;
  }
  return or;
} 
I64 FlagsPlural(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=PLURAL;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN)
      or|=ast->flags;
  }
  return or;
} 
I64 FlagsAppositive(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=0;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN)
      or|=ast->flags;
  }
  return or;
} 
I64 FlagsTransfer(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=0;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    or|=ast->flags;
  }
  return or;
} 
I64 FlagsAcc(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=ACCUSATIVE;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    or|=ast->flags;
  }
  return or;
} 

Bool NumberAgree(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  Bool plural=FALSE;
  Bool nomitive_only=FALSE;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_ADJECTIVE) {
      if(ast->flags&PLURAL)
        plural=TRUE;
    } else if(ast->act_as_type==AST_VERB) {
      nomitive_only=TRUE;
      if(ast->flags&PLURAL)
        plural=TRUE;
    }
  }
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN)
      if(nomitive_only) {
        if(ast->flags&NOMITIVE)
	  if(ToBool(ast->flags&PLURAL)^^plural)
	    return FALSE;
      } else if(ToBool(ast->flags&PLURAL)^^plural)
        return FALSE;
  }
  return TRUE;
}

Bool Transitive(I64 argc,AST **argv) {
  if(!NumberAgree(argc,argv))
    return FALSE;
  I64 i=0;
  AST *ast;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_VERB)
      if(ast->flags&INTRANSITIVE)
	  return FALSE;
  }
  return TRUE;
}
Bool Intransitive(I64 argc,AST **argv) {
  if(!NumberAgree(argc,argv))
    return FALSE;
  I64 i=0;
  AST *ast;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_VERB)
      if(ast->flags&INTRANSITIVE)
	return TRUE;
  }
  return FALSE;
}


Bool CaseAgree(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 cs=0,mask=CASE_MASK;
  while(i<argc) {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN) {
      if(!cs) {
	cs=ast->flags&mask;
      } else  {
	if((ast->flags&mask)!=cs) {
	  return FALSE;
	}
     }
    }
    i++;
  }
  return TRUE;
}
//Momitive quam albative
Bool CaseQuam(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 cs=NOMITIVE,mask=CASE_MASK;
  Bool has_nomitive=FALSE;
  Bool has_ablative=FALSE;
  while(i<argc) {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN) {
      if((ast->flags&mask)!=cs) {
	return FALSE;
      }
      if(cs&mask==NOMITIVE) {
	has_nomitive=TRUE;
	cs=ABLATIVE;
      }
      if(cs&mask==ABLATIVE) {
	has_ablative=TRUE;
	cs=ABLATIVE;
      }
    }
    i++;
  }
  return has_nomitive&&has_ablative;
}
Bool CaseX(I64 x,I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 cs=x,mask=CASE_MASK;
  while(i<argc) {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN) {
      if(!cs) {
	cs=ast->flags&mask;
      } else  {
	if(ast->flags&mask!=cs) {
	  return FALSE;
	}
     }
    }
    i++;
  }
  return TRUE;
}
Bool CaseNom(I64 argc,AST **argv) {
  return CaseX(NOMITIVE,argc,argv);
}
Bool CaseAcc(I64 argc,AST **argv) {
  return CaseX(ACCUSATIVE,argc,argv);
}
Bool CaseAbl(I64 argc,AST **argv) {
  return CaseX(ABLATIVE,argc,argv);
}
Bool CaseDat(I64 argc,AST **argv) {
  return CaseX(DATIVE,argc,argv);
}
Bool CaseGen(I64 argc,AST **argv) {
  return CaseX(GENITIVE,argc,argv);
}

U0 ParseRules(U8 *text) {
  CCmpCtrl *cc=CmpCtrlNew(text,CCF_DONT_FREE_BUF|CCF_NO_DEFINES);
  CRule *rule;
  I64 s,member_type;
  Lex(cc);
  while(cc->token) {
    rule=CAlloc(sizeof CRule);
    rule->weight=.5;
//Name
    if(cc->token!=TK_IDENT) 
      LexExcept(cc,"Expected a rule name at ");
    rule->name[0]='!';
    StrCpy(rule->name+1,cc->cur_str);
    Lex(cc);
    if(cc->token=='(') {
      Lex(cc);
      if(cc->token==TK_IDENT) {
        rule->validate_fun=StrNew(cc->cur_str);
      } else
        LexExcept(cc,"Expected function name at ");
      Lex(cc); //')'
      if(cc->token!=')')
        LexExcept(cc,"Expected ')' at ");
      Lex(cc); 
    }
    if(cc->token=='[') {
      Lex(cc);
      if(cc->token==TK_IDENT) {
        rule->flags_fun=StrNew(cc->cur_str);
      } else
        LexExcept(cc,"Expected function name at ");
      Lex(cc); //')'
      if(cc->token!=']')
        LexExcept(cc,"Expected ']' at ");
      Lex(cc); 
    }
//Put in member
    if(cc->token!=TK_IDENT) 
      LexExcept(cc,"Expected a rule class at ");
    rule->raw_type=MemberNameToI64(cc->cur_str);
    if(rule->raw_type==-1)
      LexExcept(cc,"Expected valid type at ");
    Lex(cc);
    if(cc->token==TK_DEREFERENCE) { //->
      rule->main_item_idx=-1;
      Lex(cc);
      while(cc->token==TK_IDENT||cc->token=='!'||cc->token==TK_STR) {
        member_type=-1;
        if(cc->token=='!') {
	  Lex(cc);
	  if(!rule->made_from)
	    rule->main_item_idx=0;
	  else
	    rule->main_item_idx=rule->made_from->cnt;
	  if(cc->token!=TK_IDENT&&cc->token!=TK_STR)
	    LexExcept(cc,"Expected a rule name at ");
        }
	rule->made_from=I64SetAdd(rule->made_from,StrNew(cc->cur_str),TRUE);
        Lex(cc);
        if(cc->token=='(') {
	  if(Lex(cc)!=TK_IDENT)
	    LexExcept(cc,"Expected a valid member type at ");
	  member_type=MemberNameToI64(cc->cur_str);;
	  if(member_type==-1)
	    LexExcept(cc,"Expected a valid member type at ");
	  if(Lex(cc)!=')')
	    LexExcept(cc,"Expected a ')' at ");
	  Lex(cc);
        }
        rule->member_types=I64SetAdd(rule->member_types,member_type,TRUE);
      }
      if(cc->token!=';')
        LexExcept(cc,"Expected a ',' or a ';' at ");
    } else if(cc->token=='=') {
      rule->is_word=TRUE;
      Lex(cc);
      while(cc->token==TK_IDENT) {
        rule->word_flags|=ExePrint("%s;",Define(cc->cur_str));
        if(Lex(cc)==',')
	  Lex(cc);
        else
	  break;
      }
      if(cc->token!=';')
        LexExcept(cc,"Expected a ',' or a ';' at ");
    }
    Lex(cc);
    if(cc->token=='(') {
      Lex(cc);
      if(cc->token==TK_F64) {
        rule->weight=cc->cur_f64;
      } else
        LexExcept(cc,"Expected a rule weight at ");
      Lex(cc);
      if(cc->token!=')')
        LexExcept(cc,"Expected a ')' at ");
      Lex(cc);
    }
    FramePtrAdd(rule->name,rule);
  }
  CmpCtrlDel(cc);
}
U0 AddThingToAST(AST *have,AST *to,I64 where=-1) {
  if(where==-1)
    where=have->raw_type;
  to->prob*=have->prob;
  to->args=I64SetAdd(to->args,have);
  switch(where) {
    case AST_NOUN:
      if(have->flags&CASE_MASK==0) {
	//???
        to->nomitive=ASTSetAdd(to->nomitive,have);
      } else if(have->flags&NOMITIVE){
	to->flags|=NOMITIVE;
        to->nomitive=ASTSetAdd(to->nomitive,have);
      } else if(have->flags&ACCUSATIVE){
	to->flags|=ACCUSATIVE;
        to->accusative=ASTSetAdd(to->accusative,have);
      } else if(have->flags&DATIVE){
	to->flags|=DATIVE;
        to->dative=ASTSetAdd(to->dative,have);
      } else if(have->flags&ABLATIVE){
	to->flags|=ABLATIVE;
        to->ablative=ASTSetAdd(to->ablative,have);
      } else if(have->flags&GENITIVE){
	to->flags|=GENITIVE;
        to->genitive=ASTSetAdd(to->genitive,have);
      }
      break;
    case AST_CONJUNCTION:
      to->flags|=PLURAL|have->flags;
      to->conjunction=ASTSetAdd(to->conjunction,have);
      break;
    case AST_OF:
      to->genitive=ASTSetAdd(to->genitive,have);
      break;
    case AST_WHERE:
      to->flags|=PREPOSITION;
      to->preposition=ASTSetAdd(to->preposition,have);
      break;
    case AST_ADJECTIVE:
      to->flags|=ADJECTIVE;
      to->adjective=ASTSetAdd(to->adjective,have);
      break;
    case AST_INFINITIVE:
      to->flags|=INFINITIVE;
      to->nomitive=ASTSetAdd(to->nomitive,have);
      break;
    case AST_MEASURE:
      to->measurement=ASTSetAdd(to->measurement,have);
      break;
    case AST_ADVERB:
      to->flags|=ADVERB;
      to->adverb=ASTSetAdd(to->adverb,have);
      break;
    case AST_INDIRECT_CLAUSE:
      to->nomitive=ASTSetAdd(to->nomitive,have);
      break;
    case AST_COMPARSION:
      to->measurement=ASTSetAdd(to->measurement,have);
      break;
    case AST_QUESTION:
      to->question=ASTSetAdd(to->question,have);
      break;
default:
  }
}
extern U0 Chain(CRule *chain,I64 idx,ASTSet *add_to,CGrammarState *st,I64 start_woff=0,I64 recursion_level=0);

Bool IsLeftRecursive(CRule *r) {
  if(!r) return FALSE;
  if(r->made_from)
//r->name starts with a "!"
    return !StrCmp(r->name+1,r->made_from->body[0]);
  return FALSE;
}

U0 RunRule(CGrammarState *st) {
  if(st->cnt<=0) return;
  U8 dummy[STR_LEN];
  StrPrint(dummy,"!%s",st->rule);
  FramePtrAdd(RESULTS_FP,NULL);
  I64 inst=1,idx,depth,en2,try2;
  I64 left_recursive=0;
  I64 attempt=0,find_cnt;
  CHashGeneric *h;
  CRule *r;
  AST *ret;
  CTrie **flat;
  ASTSet *results=NULL,*dummy_set;
  CGenerator *g;
  CGrammarState orig,clone;
  CTrie *word;
  MemCpy(&orig,st,sizeof CGrammarState);
again: 
  for(inst=1;h=HashFind(dummy,grammar_task->hash_table,HTT_FRAME_PTR,inst);inst++) {
    MemCpy(st,&orig,sizeof CGrammarState);
    MemCpy(&clone,st,sizeof CGrammarState);
    r=h->user_data0;
    left_recursive|=IsLeftRecursive(r);
//TODO allow other forms of the word
    if(GetWord(r->name)&&IsFormOf(r->name,st->words[0])) {
      word=GetWord(st->words[0]);
      while(word) {
        ret=CAlloc(sizeof(AST),mem_task);
        ret->prob=1.;
        ret->word_idx=st->woff;
        if(r->raw_type) { 
	  ret->act_as_type=ret->raw_type=r->raw_type;
        } else if(word->flags&NOUN) {
	  ret->act_as_type=ret->raw_type=AST_NOUN;
        } else if(word->flags&VERB) {
	  ret->act_as_type=ret->raw_type=AST_VERB;
        } else if(word->flags&CONJUNCTION) {
	  ret->act_as_type=ret->raw_type=AST_CONJUNCTION;
        } else if(word->flags&ADJECTIVE) {
	  ret->act_as_type=ret->raw_type=AST_ADJECTIVE;
        } else if(word->flags&INFINITIVE) {
	  ret->act_as_type=ret->raw_type=AST_INFINITIVE;
        } else if(word->flags&ADVERB) {
	  ret->act_as_type=ret->raw_type=AST_ADVERB;
        }

        ret->word=word;
        ret->flags=word->flags;
        ret->end=1;
        ret->prob=r->weight;
        ret->args=I64SetAdd(ret->args,ret);
        FramePtrSet(RESULTS_FP,ASTSetAdd(FramePtr(RESULTS_FP),ASTClone(ret)));
        GeneratorYield(ret);
        word=word->next;
      }
    }
    if(r->is_word) {
      word=GetWord(st->words[0]);
      while(word&&!attempt) {
        if(st->en) *st->en=1;
        if(word->flags&r->word_flags==r->word_flags) {
	  ret=CAlloc(sizeof(AST),mem_task);
	  ret->prob=1.;
	  ret->word_idx=st->woff;
	  ret->act_as_type=ret->raw_type=r->raw_type;
	  ret->word=word;
	  ret->flags=word->flags;
	  ret->end=1;
	  ret->prob=r->weight;
	  ret->args=I64SetAdd(ret->args,ret);
	  FramePtrSet(RESULTS_FP,ASTSetAdd(FramePtr(RESULTS_FP),ASTClone(ret)));
	  GeneratorYield(ret);
        }
        word=word->next;
      }
    } else {
      if(r->made_from) {
        if(attempt) {
	  if(results&&IsLeftRecursive(r)) {
	    for(idx=0;idx!=results->cnt;idx++) {
	      ret=results->body[idx];
	      dummy_set=ASTSetAdd(NULL,ASTClone(ret));
	      MemCpy(&clone,st,sizeof CGrammarState);
	      clone.is_conj2=TRUE;
	      clone.woff+=ret->end;
	      clone.cnt-=ret->end;
	      clone.words+=ret->end;
	      Chain(r,1,dummy_set,&clone,st->woff,attempt);
	      ASTSetDel(dummy_set);
	    }
	  }
        } else if(!IsLeftRecursive(r)) {
	  MemCpy(&clone,st,sizeof CGrammarState);
	  Chain(r,0,NULL,&clone,st->woff,attempt);
        }
      }
    }
skip:;
  }
//Do "sub-parts" outside of the nain loop;WE ONLY NEED TO COMPUTE ONCE
  if(!attempt)
    if(!StrCmp(st->words[0],"[")) {
      depth=0;
      for(idx=0;idx<st->cnt;idx++) {
        if(!StrCmp(st->words[idx],"["))
	  depth++;
        else if(!StrCmp(st->words[idx],"]"))
	  depth--;
        if(!depth) break;
      }
      if(!depth) {
        MemCpy(&clone,st,sizeof CGrammarState);
        clone.woff++;
        clone.words++;
        clone.cnt=idx-1;
        clone.en=&en2;
        g=GeneratorNewC(&RunRule,&clone);
        while(GeneratorGet(g,&ret)) {
	  if(en2==idx-1) {
	    if(st->en) *st->en=idx+1;
	    ret->end=idx+1;
	    FramePtrSet(RESULTS_FP,ASTSetAdd(FramePtr(RESULTS_FP),ASTClone(ret)));
	    GeneratorYield(ret);
	  } else 
	    ASTDel(ret);
        }
      }
    }
  if(!left_recursive)
    goto fin;
  results=FramePtr(RESULTS_FP);
  FramePtrSet(RESULTS_FP,NULL);
  if(attempt++) {
fin:
    if(FramePtr(RESULTS_FP))
      ASTSetDel(FramePtr(RESULTS_FP));
    FramePtrDel(RESULTS_FP);
    return;
  }
  goto again;
}

U0 Chain(CRule *rule,I64 idx,ASTSet *add_to,CGrammarState *st,I64 start_woff=0,I64) {
  CGrammarState orig,clone,clone2;
  AST *grab,*tmp,*main=NULL,*conj2;
  CGenerator *g;
  I64Set *chain=rule->made_from;
  I64 width,dummy,main_idx,depth,idx2,cnt;
  CTrie **flat;
//Avoid infinitie left recursion
  CHashGeneric *h;
  U8 buf[STR_LEN];
  StrPrint(buf,"PrntRule:%d,%x",st->woff,rule);
  if(!idx)  {
    dummy=1;
    if(FramePtr(buf)) {
      return;
    }
    FramePtrAdd(buf,1);
  }
  if(!st->en) st->en=&dummy;
  if(idx>chain->cnt)
    return;
  if(idx==chain->cnt) {
    if(!add_to) return;
    if(st->en) *st->en=st->woff-start_woff;
    for(idx=0;idx!=add_to->cnt;idx++) {
      if(idx==rule->main_item_idx) {
        main=add_to->body[idx];
        main_idx=idx;
        break;
      }
    } 

    if(!main) {
      main=add_to->body[0];
      main_idx=0;
    }

    main=ASTClone(main);
    main->end=st->woff-start_woff;
    main->raw_type=main->act_as_type=rule->raw_type;
    for(idx=0;idx!=add_to->cnt;idx++) {
      if(main_idx!=idx)
        AddThingToAST(ASTClone(add_to->body[idx]),main,rule->member_types->body[idx]);
    }
    main->prob*=rule->weight;
    if(rule->flags_fun&&main->args)
      main->flags|=CallExtStr(rule->flags_fun,main->args->cnt,main->args->body);
    if(rule->validate_fun&&main->args) {
      if(CallExtStr(rule->validate_fun,main->args->cnt,main->args->body)) {
        FramePtrSet(RESULTS_FP,ASTSetAdd(FramePtr(RESULTS_FP),ASTClone(main)));    
        GeneratorYield(main);
      }
    } else{
      FramePtrSet(RESULTS_FP,ASTSetAdd(FramePtr(RESULTS_FP),ASTClone(main)));
      GeneratorYield(main);
    }
    return;
  }
  MemCpy(&orig,st,sizeof CGrammarState);
  MemCpy(&clone,st,sizeof CGrammarState);
  clone.en=&width;
  clone.rule=chain->body[idx];
  g=GeneratorNewC(&RunRule,&clone);
  while(GeneratorGet(g,&grab)) {
    MemCpy(&clone2,&orig,sizeof CGrammarState);
    clone2.woff+=width;
    clone2.cnt-=width;
    clone2.words+=width;
    tmp=ASTSetClone(add_to);
    tmp=ASTSetAdd(tmp,ASTClone(grab));
    Chain(rule,idx+1,tmp,&clone2,start_woff,0);
    if(!st->is_conj2) {
      MemCpy(&clone2,&orig,sizeof CGrammarState);
      clone2.woff+=width;
      clone2.cnt-=width;
      clone2.words+=width;
      cnt=ASTGetTrieWords(grab,NULL);
      flat=CAlloc(8*(cnt+1)); //cnt here is the last word_idx,add 1
      ASTGetTrieWords(grab,flat);
      for(idx2=0;idx2<=cnt;idx2++) {
        if(flat[idx2]) {
	  if(flat[idx2]->flags&CONJUNCTION2) {
	    main=CAlloc(sizeof(AST),mem_task);
	    main->prob=1.;
	    main->word_idx=st->woff;
	    main->act_as_type=main->raw_type=AST_CONJUNCTION;
	    main->word=flat[idx2];
	    main->end=1;
	    main->args=I64SetAdd(main->args,main);
	    conj2=ASTSetClone(add_to);
	    conj2=ASTSetAdd(conj2,main);
	    conj2=ASTSetAdd(conj2,ASTClone(grab));
	    Chain(rule,idx+2,tmp,&clone2,start_woff,0);
	  }
	  break;
        }
      }
      Free(flat);
    }
    ASTDel(grab);
    ASTSetDel(tmp);
  }
  if(!idx)
    FramePtrDel(buf);
}
U8*rules=FileRead("Latin.GMR");
ParseRules(rules);
Free(rules);
