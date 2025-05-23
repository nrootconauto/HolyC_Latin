#ifndef RULE_SET_HH
#define RULE_SET_HH "Logos"
#include "GrammarAST.HC"
#define LIMIT_FP "GenCap"
#define CNT_FP "GenCnt"
#define RESULTS_FP "Results"
CTask *grammar_task=Fs;
I64 tmp_rule_idx=0;
ASTSet *ASTSetTrim(ASTSet *set) {
  return set;
  if(!set) return set;
  Bool changed=FALSE;
  I64 idx,idx2;
  AST *a,*b;
enter:;
  for(idx=0;idx!=set->cnt;idx++)
    for(idx2=0;idx2!=set->cnt;idx2++) {
a=set->body[idx],b=set->body[idx2];
      if(a!=b&&ASTCompatible(a,b)) {
        if(a->prob>b->prob) {
//Remove b from set
	  MemCpy(&set->body[idx2],&set->body[idx2+1],8*(set->cnt-idx2-1));
	  ASTDel(b);
	  --set->cnt;
	  goto enter;
	}
      }
    }
  return set;
}
I64 ASTScoreSortRev(AST *a,AST *b) {
  if(b->prob>a->prob)
    return 1;
  if(b->prob<a->prob)
    return -1;
  return 0;
} 
ASTSet *ASTSetAddSmart(ASTSet *set,AST *a) {
  if(!set) return ASTSetAdd(set,a);
  I64 cnt=set->cnt;
  AST *tmp;
  while(--cnt>=0)
    if(ASTCompatible(a,tmp=set->body[cnt])) {
      if(a->prob<tmp->prob)
        ASTDel(a);
      else  {
        set->body[cnt]=a;
      }
      goto fin;
    }
  set=ASTSetAdd(set,a);
fin:;
  QSortI64(set->body,set->cnt,&ASTScoreSortRev);
  return set;
}
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
#define PART_MASK (VERB|NOUN|ADVERB|ADJECTIVE|CONJUNCTION|PREPOSITION)
#define CASE_MASK (NOMITIVE|ACCUSATIVE|ABLATIVE|DATIVE|VOCATIVE)
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


I64 FlagsPrep(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=0;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_WHERE)
	break;
    if(ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE) {
      or|=ast->flags;
    }
  }
  return or;
} 

I64 FlagsConj(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=PLURAL;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE)
      or|=ast->flags;
  }
  return or&~(SINGULAR|CONJUNCTION);
} 


I64 FlagsPlural(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=PLURAL;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE)
      or|=ast->flags;
  }
  return or;
} 

I64 FlagsColon(I64 argc,AST **argv) {
  return CONJUNCTION_NO_JOIN|CONJUNCTION|argv[0]->flags;
} 

I64 FlagsComma(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=0;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_VERB||ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE)
      or|=ast->flags;
  }
  return or|CONJUNCTION;
} 



I64 FlagsPluralQue(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=PLURAL|CONJUNCTION2;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    if(ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE)
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
I64 FlagsTransferAdj(I64 argc,AST **argv) {
  return (FlagsTransfer(argc,argv)&~PART_MASK)|ADJECTIVE;
}
I64 FlagsTransferNoun(I64 argc,AST **argv) {
  return (FlagsTransfer(argc,argv)&~PART_MASK)|NOUN;
}
I64 FlagsTransferVerb(I64 argc,AST **argv) {
  return (FlagsTransfer(argc,argv)&~PART_MASK)|VERB;
}
I64 FlagsTransferAdv(I64 argc,AST **argv) {
  return (FlagsTransfer(argc,argv)&~PART_MASK)|ADVERB;
}
I64 FlagsTransferNoConj(I64 argc,I64 *argv) {
  return FlagsTransfer(argc,argv)&~(CONJUNCTION|CONJUNCTION2);
}

I64 FlagsTransferGen(I64 argc,I64 **argv) {
  return FlagsTransfer(argc,argv)&~GENITIVE;
}
I64 FlagsAdj(I64 argc,I64 **argv) {
  I64 r=FlagsTransfer(argc,argv)&~ADJECTIVE;
  return r;
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
I64 FlagsNom(I64 argc,AST **argv) {
  I64 i=0;
  AST *ast;
  I64 or=NOMITIVE;
  for(i=0;i!=argc;i++)  {
    ast=argv[i];
    or|=ast->flags;
  }
  return or;
} 

U8 *error;
Bool VerbAgree(I64 argc,AST **argv) {
  I64 nom=FALSE,acc=FALSE;
  I64 dat=FALSE,abl=FALSE;
  I64 voc=FALSE;
  I64 i;
  AST*a;
  for(i=0;i!=argc;i++)  {
    a=argv[i];
    if(a->flags&NOMITIVE)
      if(nom++) {
	error=GCStrNew("Multiple Nomitives");
	return FALSE;
      }
    if(a->flags&ACCUSATIVE)
      if(acc++) {
	error=GCStrNew("Multiple Accusatives");
	return FALSE;
      }
    if(a->flags&ABLATIVE)
      if(abl++) {
	error=GCStrNew("Multiple Ablatives");
	return FALSE;
      }
    if(a->flags&DATIVE)
      if(dat++) {
	error=GCStrNew("Multiple Datives");
	return FALSE;
      }
    if(a->flags&VOCATIVE)
      if(voc++) {
	error=GCStrNew("Multiple Vocatives");
	return FALSE;
      }
  }
  return TRUE;
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
	  if(ToBool(ast->flags&PLURAL)^^plural) {
	    error=GCStrNew("Number disagree");
	    return FALSE;
	  }
      } else if(ToBool(ast->flags&PLURAL)^^plural) {
        error=GCStrNew("Number disagree");
        return FALSE;
      }
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
    if(ast->act_as_type==AST_NOUN||ast->act_as_type==AST_ADJECTIVE) {
pass:;
      if(!cs) {
	cs=ast->flags&mask;

//	if(!cs) //????
//	  return FALSE;
      } else {
	if((ast->flags&mask)!=cs) {
          error=GCStrNew("Case disagree");
	  return FALSE;
	}
      }
    }
    i++;
  }
  return TRUE;
}

Bool HasQueAtEnd(I64 argc,AST **argv) {
  AST *ast=argv[argc-1];
  if(ast->flags&CONJUNCTION2)
    return TRUE;
  return ast->word&&ast->word->flags&CONJUNCTION2;
}
Bool HasQueAtEndWithCase(I64 argc,AST **argv) {
  if(!CaseAgree(argc,argv))
    return FALSE;
  AST *ast=argv[argc-1];
  if(ast->flags&CONJUNCTION2) {
    return TRUE;
  }
  return ast->word&&ast->word->flags&CONJUNCTION2;
}


//Momitive quam albative
Bool CaseQuam(I64 argc,AST **argv) {
//https://latinforaddicts.wordpress.com/2012/04/16/uses-of-quam-subjunctive/
//Words are in same case
  if(CaseAgree(argc,argv))
    return TRUE;
  return FALSE;
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
I64Set *rules_list=NULL;
CRule *ParseFormula(CCmpCtrl *cc,CRule *rule) {
  I64 member_type;
  U8 buf[STR_LEN+8];
  CRule *r2;
  rule->weight=1;
  while(cc->token==TK_IDENT||cc->token=='!'||cc->token==TK_STR||cc->token=='[') {
    member_type=-1;
    if(cc->token=='[') {
      Lex(cc);
      r2=GCCAlloc(sizeof CRule);
      ParseFormula(cc,r2);
      StrPrint(r2->name,"!TMP.%d",tmp_rule_idx++);
      if(!r2)
        throw('RuleSet');
      if(cc->token!=']') {
        LexExcept(cc,"Expcted a '[' at ");
      }
      Lex(cc);
      if(cc->token=='(') {
        if(Lex(cc)!=TK_IDENT)
	  LexExcept(cc,"Expected a valid member type at ");
        member_type=MemberNameToI64(cc->cur_str);;
        if(member_type==-1)
	  LexExcept(cc,"Expected a valid member type at ");
        if(Lex(cc)!=')')
	  LexExcept(cc,"Expected a ')' at ");
      } else 
	LexExcept(cc,"Expected a '(NOUN/VERB/WHERE...)'");

      rule->made_from=I64SetAdd(rule->made_from,StrNew(r2->name),TRUE);
      r2->raw_type=member_type;
      rules_list=I64SetAdd(rules_list,r2);
      goto pass;
    }
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
    if(cc->token==TK_STR) {
      StrPrint(buf,"WR.%s",cc->cur_str);
      if(!FramePtr(buf)) {
        r2=GCCAlloc(sizeof CRule);
	r2->weight=1;
	r2->is_word=1;
	r2->word_flags=INVALID_PTR;
	StrCpy(r2->name,cc->cur_str);
	FramePtrAdd(buf,1);
	rules_list=I64SetAdd(rules_list,r2);
      }
    }
pass:;
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
  return rule;
}
U0 ParseRules(U8 *text) {
  CCmpCtrl *cc=CmpCtrlNew(text,CCF_DONT_FREE_BUF|CCF_NO_DEFINES);
  CRule *rule,*r2;
  I64 s,member_type;
  Lex(cc);
  while(cc->token) {
    rule=GCCAlloc(sizeof CRule);
    rule->weight=1;
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
      rule->main_item_idx=0;
      Lex(cc);
      ParseFormula(cc,rule);
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
      } else if(cc->token==TK_I64) {
        rule->weight=cc->cur_i64;
      } else
        LexExcept(cc,"Expected a rule weight at ");
      Lex(cc);
      if(cc->token!=')')
        LexExcept(cc,"Expected a ')' at ");
      Lex(cc);
    }
    FramePtrAdd(rule->name,rule);
    rules_list=I64SetAdd(rules_list,rule);
    StrCpy(rule->name,rule->name+1);
  }
  CmpCtrlDel(cc);
}
U0 AddThingToAST(AST *have,AST *to,I64 where=-1) {
  if(where==-1)
    where=have->raw_type;
  to->args=I64SetAdd(to->args,have);
  switch(where) {
    case AST_NOUN:
      if(have->flags&NOMITIVE){
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
      } else {
//???? TODOvocative
	to->flags|=NOMITIVE;
        to->nomitive=ASTSetAdd(to->nomitive,have);
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
    case AST_VERB:
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
DumpAST(have);
DumpAST(to);
"FUCK,%d\n",where;
Break;
  }
}

Bool IsLeftRecursive(CRule *r) {
  if(!r) return FALSE;
  if(r->made_from)
//r->name starts with a "!"
    return !StrCmp(r->name+1,r->made_from->body[0]);
  return FALSE;
}
I64Set **MatrixPtr(U8 **matrix,I64 x,I64 y,I64 cnt) {
  return &matrix[x+y*cnt];
}
Bool RulePost(AST *ast,CRule *rule,I64 *args,I64 arg_cnt) {
  Bool ret=TRUE;
  error=NULL;
  if(rule->validate_fun)
    if(!CallExtStr(rule->validate_fun,arg_cnt,args)) {
      if(!FramePtr("GrammarCheck")||!error)
        ret=FALSE;
      ast->error=error;
    }
  if(rule->flags_fun) {
     if(!HashFind(rule->flags_fun,Fs->hash_table,HTT_FUN))
	"UNK:%s\n",rule->flags_fun;
    ast->flags=CallExtStr(rule->flags_fun,arg_cnt,args);
  }
  return ret;
}
ASTSet *DoTerminals(U8 *_word,I64 idx,U8 *force) {
  I64 i=rules_list->cnt;
  CRule *rule;
  CTrie *word;
  AST *ret;
  ASTSet *all=NULL;
  while(--i>=0) {
    rule=rules_list->body[i];
    if(force&&StrCmp(force,rule->name))
      goto skip;
    if(rule->is_word) {
      if(!StrCmp(_word,",")) {
	word=GetWord(LATIN_TRIE_COMMA);
	goto enter;
      }
      if(!StrCmp(_word,":")) {
	word=GetWord(LATIN_TRIE_COLON);
	goto enter;
      }
      if(!StrCmp(_word,";")) {
	word=GetWord(LATIN_TRIE_SEMICOLON);
	goto enter;
      }
      if(word=GetWord(_word)) {
enter:
        while(word) {
	  if((word->flags&rule->word_flags==rule->word_flags)||!StrICmp(_word,rule->name)) {
	    ret=GCCAlloc(sizeof(AST));
	    ret->prob=rule->weight;
	    ret->word_idx=idx;
	    ret->act_as_type=AST_NOUN;
	    ret->raw_type=AST_NOUN;
	    if(rule->raw_type) { 
	      ret->act_as_type=ret->raw_type=rule->raw_type;
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
	    } else if(!StrCmp(_word,":")||!StrCmp(_word,",")||!StrCmp(_word,";"))
	      ret->act_as_type=ret->raw_type=AST_CONJUNCTION;
	    ret->word=word;
	    ret->flags=word->flags;
	    ret->end=idx+1;
	    ret->start=idx;
	    ret->args=I64SetAdd(ret->args,ret);
	    ret->rule=rule;

	    if(ret->flags&VOCATIVE)
	      ret->prob/=3.;
	    if(ret->flags&ABLATIVE)
	      ret->prob/=2.;
	    if(ret->flags&DATIVE)
	      ret->prob/=2.;
	    if(ret->flags&GENITIVE)
	      ret->prob/=2.;

	    if(RulePost(ret,rule,ret->args->body,ret->args->cnt)) {
	      all=ASTSetAddSmart(all,ret);
	    }
	  }
	  word=word->next;
        }
      }
    }
skip:;
  }
  if(all)
    QSortI64(all->body,all->cnt,&ASTScoreSortRev);
  return all;
}
I64 Next(U8 **words,I64 x,I64 cnt,Bool next=TRUE){
  I64 bracket_depth=0;
  if(!StrCmp(words[x],"[")) {
    bracket_depth=1;
    ++x;
    while(bracket_depth&&x<cnt) {
      if(!StrCmp(words[x],"[")) {
        bracket_depth++;
        x++;
      } if(!StrCmp(words[x],"]")) {
        bracket_depth--;
        x++;
      } else
        x++;
    }
fin:;
    if(next&&x+2<=cnt) {
      if(!StrCmp(words[x],"=")) {
	x+=2;
      }
    }
    return x;
  } 
  ++x;
  goto fin;
}
I64 SubExprWidth(U8 **words,I64 x,I64 cnt) {
  return Next(words,x,cnt,FALSE)-x-2;
}
Bool HasExpectedRulesAhead(U8 **words,CRule *r,U8 **matrix,I64 y,I64 cnt,I64 x=0,I64 ra=0) {
  if(ra>=r->made_from->cnt)
    return TRUE;
  while(x<cnt) {
    if(!StrCmp(words[x],"]"))
      x++;
    else
      break;
  }
  if(cnt-x<r->made_from->cnt-ra)
    return FALSE;
  I64 idx;
  I64Set *tested_offsets=NULL;
  Bool has=FALSE;
  ASTSet *as=*MatrixPtr(matrix,x,y,cnt);
  AST *cur;
  if(as)
    for(idx=0;idx!=as->cnt;idx++) {
//Rule name is first member of ->rule
      cur=as->body[idx];
      if(!StrCmp(r->made_from->body[ra],cur->rule)) {
        if(!I64SetHasItem(tested_offsets,cur->end)) {
	  tested_offsets=I64SetAdd(tested_offsets,cur->end);
	  has|=HasExpectedRulesAhead(words,r,matrix,y,cnt,cur->end,ra+1);
        }
      }
      if(has)
        break;
    }
  GCFree(tested_offsets);
  if(!has&&!StrCmp(words[x],"[")) {
    has|=HasExpectedRulesAhead(words,r,matrix,y,cnt,x+1,ra);
  }
  return has;

}

ASTSet *Scan(U8 **words,ASTSet *add_to,CRule *r,U8 **matrix,I64 y,I64 cnt,I64 x=0,I64 ra=0,ASTSet *args=NULL) {
  if(!HasExpectedRulesAhead(words,r,matrix,y,cnt,AbsI64(x),ra))
    return add_to;
  I64 next;
  ASTSet *cell;
  AST *tmp,*ret;
  CRule *rule;
  ASTSet *old=add_to;
  if(!r->made_from)
    return add_to;
  I64 rcnt=r->made_from->cnt,idx;
  I64 boundary,attempt;
  U8 *desired,*tmp2;
  U8 *accept_rule=NULL;
  I64 repeat_cnt=0;
//Short circuit logic,if wanted input is longer than available items,just quit
  if(rcnt-ra>cnt-AbsI64(x))
    return add_to;
//Check for word=Rule@Rule
  if(AbsI64(x)<cnt&&AbsI64(x)-1>=0) {
    if(!StrCmp(words[AbsI64(x)-1],"="))
      return add_to;
  }
//Check for =Rule@Rule(rule forcing)
  if(AbsI64(x)+2<=cnt) {
    idx=Next(words,AbsI64(x),cnt,FALSE);
    if(idx<cnt&&!StrCmp(words[idx],"=")) {
      if(StrCmp(r->name,words[idx+1])) {
        accept_rule=words[idx+1];
      }
    }
  }
  if(ra>=rcnt) {
pass:
    if(r->main_item_idx>=0) {
      tmp=args->body[r->main_item_idx];
      if(args->cnt>1) {
        ret=GCCAlloc(sizeof(AST));
        ret->flags=tmp->flags;
        ret->base_expression=ASTClone(tmp);
        ret->base_expression->parent_node=ret;
        ret->args=NULL;
      } else
        ret=ASTClone(tmp);
    } else
      Break;
    ret->prob=r->weight;
    ret->rule=r;
    ret->raw_type=ret->act_as_type=r->raw_type;
    ret->start=tmp->start;
    ret->end=tmp->end;
//DONT make an item have a single child,just "overshadow" it
    if(args->cnt==1) {
	if(ret->start==ret->end+1) {
//
      //  Dumb Hack!!!
      //
      //  If we have velox=Adj@Adj,be sure to include "=Adj@Adj" in the ->end
      //
      ret->end=Next(words,ret->start,cnt);
      }
    } else {
      tmp=args->body[0];
      ret->start=tmp->start;
/***********************************************
MAKE SURE ARGUMNENTS DONT OVERLAP,use boundary.
************************************************/
      boundary=tmp->end;
      for(idx=1;idx<args->cnt;idx++) {
        tmp=args->body[idx];
        if(boundary!=tmp->start) {
	  goto fail;
        }
        boundary=tmp->end;
      }
      ret->end=boundary;
      for(idx=0;idx!=args->cnt;idx++) {
        tmp=args->body[idx];
        if(r->main_item_idx!=idx) {
	  AddThingToAST(ASTClone(tmp),ret);
        }
	ret->prob*=tmp->prob;
      }
    }
    if(RulePost(ret,r,args->body,ra)) {
      repeat_cnt=FramePtr("RS.Added");
      FramePtrSet("RS.Added",repeat_cnt+1);
      add_to=ASTSetAddSmart(add_to,ret);
    } else {
fail:;
      ret->args=NULL;
      ASTDel(ret);
      ret=NULL;
    }
    return add_to;
  }	
  desired=r->made_from->body[ra];
  if(x>=cnt)
    return add_to;
  cell=*MatrixPtr(matrix,x,y,cnt);
//Check for ]
  if(!StrCmp(words[AbsI64(x)],"]"))
    return add_to;
  for(attempt=0;attempt!=2;attempt++) {
    repeat_cnt=0;
    if(AbsI64(x)+attempt>=cnt)
      return add_to;
    cell=*MatrixPtr(matrix,AbsI64(x)+attempt,y,cnt);
    if(cell)
      for(idx=0;idx!=cell->cnt;idx++) {
        tmp=cell->body[idx];
        if(attempt) {
//If you are in attempt==1,that means [expression]
	  //Check if expression spans full range between "["and "]"
	  if(tmp->end-tmp->start!=SubExprWidth(words,AbsI64(x),cnt)) {
	    goto skip;
	  } else{
	    tmp=ASTClone(tmp);
	    tmp->start=AbsI64(x);
	    tmp->end=Next(words,tmp->start,cnt);
	  }
        } else
	  tmp=ASTClone(tmp);

        if(accept_rule) {
	  if(StrCmp(accept_rule,tmp->rule->name))
	    goto skip;
        }
        if(!StrCmp(desired,tmp->rule->name)) {
	  if(args)
	    tmp2=I64SetAdd(GCMAllocIdent(args),tmp);
	  else
	    tmp2=I64SetAdd(NULL,tmp);
	  old=add_to;
	  add_to=Scan(words,add_to,r,matrix,y,cnt,tmp->end,ra+1,tmp2);
	  GCFree(tmp2);
	  repeat_cnt=FramePtr("RS.Added");
	  if(repeat_cnt>=21) {
	    ASTDel(tmp);
	    goto fin;
	  }
        }
//Heres the deal,if we encounter a "[",that is the same as our rule,
        //Just use it("[Sentence]"  is the same as "Sentence")
        if(attempt&&r==tmp->rule)
	  add_to=ASTSetAddSmart(add_to,ASTClone(tmp));
        ASTDel(tmp);
skip:;
      }
skip2:;
    if(StrCmp(words[AbsI64(x)],"["))
      break;
  }
fin:;
  return add_to;
}
I64Set *PackratMatrix(U8 **words,I64 cnt) {
  I64Set **matrix=GCCAlloc(sizeof(I64Set*)*cnt*cnt);
  ASTSet **ptr,*new;
  CRule *rule;
  AST *old;
  I64 x,y;
  I64 rc=rules_list->cnt,tries;
  I64 ri;
  I64 old_cnt;
  Bool has_force;
  U8 *force;
  for(x=0;x!=cnt;x++)
    for(y=0;y!=cnt;y++) {
      *MatrixPtr(matrix,x,y,cnt)=NULL;
    }
  for(x=cnt-1;x>=0;--x) {
    has_force=FALSE;
    force=NULL;
    if(x+2<=cnt) {
      if(!StrCmp(words[x+1],"=")) {
        force=words[x+2];
        has_force=TRUE;
      }
    }
    ptr=MatrixPtr(matrix,x,cnt-1,cnt);
    *ptr=DoTerminals(words[x],x,force);
//If we force a rule,be sure to account for the distance of (=Forced@Rule)
    if(has_force&&*ptr) {
      for(y=ptr[0]->cnt;--y>=0;) {
        old=ptr[0]->body[y];
        old->end+=2; // =Rule
      }
    }
  }

  //tries is set to 2 to handle recursion,but not forever
  y=cnt-2;
  for(tries=0;tries!=2;tries++) {
    for(x=cnt-1;x>=0;x--) {
      for(ri=0;ri!=rc;ri++) {
        rule=rules_list->body[ri];
        if(rule->made_from) {
	  ptr=MatrixPtr(matrix,x,y+1,cnt);
	  FramePtrAdd("RS.Added",0);
	  new=Scan(words,GCMAllocIdent(*ptr),rule,matrix,y+1,cnt,-x);
	  FramePtrDel("RS.Added");
	  GCFree(*ptr);
	  new=ASTSetTrim(new);
	  *ptr=new;
        }
      }
    }
  }

  return matrix;
}
Bool ASTHasErrors(AST *ast) {
  Bool ret=FALSE;
  I64 i;
  I64Set *set;
  if(!ast) return FALSE;
  if(ast->error) return TRUE;
  ret|=ASTHasErrors(ast->base_expression);
  if(set=ast->args) {
    for(i=0;i!=set->cnt;++i) 
      if(ast!=set->body[i])
        ret|=ASTHasErrors(set->body[i]);
  }
  return ret;
}
AST *ParseSentenceJoin(I64 argc,U8 **argv) {
  U8 **matrix=PackratMatrix(argv,argc);
  Bool has_good=FALSE;
  AST *ret=NULL,*cur;
  ASTSet *set;
  I64 y;
  I64 ass,best_len=0;
  F64 best_prob=-10000.,mul;
  Bool check=FramePtr("GrammarCheck");
  for(y=0;y!=argc;y++) {
    set=*MatrixPtr(matrix,0,y,argc);
    if(set) {
      I64 can=set->cnt;
      while(--can>=0) {
        cur=set->body[can];
        if(cur->start==0&&cur->end==argc)
	  has_good|=!ASTHasErrors(cur);
	else if(cur->start==0)
	  best_len=MaxI64(cur->end,best_len);
      }
      can=set->cnt;
      while(--can>=0) {
        cur=set->body[can];
        if((cur->start==0&&cur->end==argc)||(!has_good&&cur->start==0&&cur->end==best_len&&check)) {
          if(!ASTHasErrors(cur)) {
	    mul=1.;
	  } else { //cur->error==TRUE
	    mul=1.;
	    if(has_good) {
	      mul=0.;
	      goto skip;
	    }
	  }
	  if(best_prob<=mul*cur->prob) {
	    if(ret) ASTDel(ret);
	    best_prob=mul*cur->prob;
	    ret=ASTClone(cur);
	  }
skip:; 
        }
      }
    }
  }
  for(y=0;y!=argc*argc;y++) {
    cur=matrix[y];
    if(cur)
      ASTSetDel(cur);
  }
  GCFree(matrix);
  return ret;
}
AST *ParseSentence(...) {
  return ParseSentenceJoin(argc,argv);
}

U8*rules=FileRead("Latin.GMR");
ParseRules(rules);
Free(rules);
#endif