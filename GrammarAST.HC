#include "GarbageCollector.HC";

 //I must deposit a turd to the porcelain throne
#include "Latin.HC";
#include "Generator.HC";
#define AST_NOUN 1
#define AST_CONJUNCTION 2
#define AST_VERB 3
#define AST_OF 4
#define AST_WHERE 5
#define AST_ADJECTIVE 6
#define AST_INFINITIVE 7
//The boy is 5 feet tall
#define AST_MEASURE 8
#define AST_ADVERB 9
//He was [eating pie]
#define AST_INDIRECT_CLAUSE 10
#define AST_COMPARSION 11
#define AST_QUESTION 12
extern class AST;
extern class CDisplayNode;
CTask *mem_task=Fs;
CTask *debug_log_task=Fs;
class ASTSet {
  I64 cnt;
  AST *body[0]; 
};
extern class CRule;
class AST {
  CRule *rule;
  F64 prob,final_prob;
  I64 number;
  U8 *note;
  U8 *error;
  I64 raw_type,act_as_type;
  I64 flags; //From Latin.HC
  ASTSet *nomitive;
  ASTSet *accusative;
  ASTSet *dative;
  ASTSet *ablative;
  ASTSet *genitive;
  ASTSet *adjective;
  ASTSet *preposition;
  ASTSet *conjunction;
  ASTSet *measurement;
  ASTSet *adverb;
  ASTSet *question;
  I64Set *args; //Dont free
  CTrie *word; //May be NULL,if NULL use base_expression
  I64 word_idx;
  AST *base_expression;
  AST *parent_node; //For base_expression
  CDisplayNode *disp_node;
//Private
  I64 start;
  I64 end;
};
extern U0 DumpAST(AST*a);
extern ASTSet *ASTSetClone(ASTSet *orig);

ASTSet *ASTSetAdd(ASTSet *dst,AST *a) {
  if(!a) return dst;
  ASTSet *tmp;
  if(!dst) {
    dst=GCCAlloc(sizeof(ASTSet)+8);
    dst->cnt=1;
    dst->body[0]=a;
    return dst;
  }
  tmp=GCCAlloc(sizeof(ASTSet)+8*(dst->cnt+1));
  tmp->cnt=dst->cnt+1;
  MemCpy(tmp->body,dst->body,dst->cnt*8);
  tmp->body[tmp->cnt-1]=a;
  GCFree(dst);
  return tmp;
}
ASTSet *ASTSetAddAll(ASTSet *a,ASTSet *b) {
  if(!b) return a;
  I64 i=b->cnt;
  while(--i>=0)
    a=ASTSetAdd(a,b->body[i]);
  return a;
}


AST *ASTClone(AST *orig) {
  static I64 cnt=0;
  AST *ret=GCCAlloc(sizeof(AST));
  MemCpy(ret,orig,sizeof AST);
  ret->note=GCStrNew(ret->note);
  ret->disp_node=NULL;
  if(ret->base_expression) {
    ret->base_expression=ASTClone(ret->base_expression);
    ret->base_expression->parent_node=ret;
  }
  ret->nomitive=ASTSetClone(ret->nomitive);
  ret->accusative=ASTSetClone(ret->accusative);
  ret->dative=ASTSetClone(ret->dative);
  ret->ablative=ASTSetClone(ret->ablative);
  ret->genitive=ASTSetClone(ret->genitive);
  ret->adjective=ASTSetClone(ret->adjective);
  ret->preposition=ASTSetClone(ret->preposition);
  ret->conjunction=ASTSetClone(ret->conjunction);
  ret->measurement=ASTSetClone(ret->measurement);
  ret->adverb=ASTSetClone(ret->adverb);
  ret->question=ASTSetClone(ret->question);
  ret->args=I64SetAdd(NULL,ret);
  ret->args=ASTSetAddAll(ret->args,ret->nomitive);
  ret->args=ASTSetAddAll(ret->args,ret->ablative);
  ret->args=ASTSetAddAll(ret->args,ret->accusative);
  ret->args=ASTSetAddAll(ret->args,ret->dative);
  ret->args=ASTSetAddAll(ret->args,ret->genitive);
  ret->args=ASTSetAddAll(ret->args,ret->adjective);
  ret->args=ASTSetAddAll(ret->args,ret->preposition);
  ret->args=ASTSetAddAll(ret->args,ret->conjunction);
  ret->args=ASTSetAddAll(ret->args,ret->measurement);
  ret->args=ASTSetAddAll(ret->args,ret->adverb);
  ret->args=ASTSetAddAll(ret->args,ret->question);
  return ret;
}
Bool ASTCompatible(AST *a,AST *b) {
  if(a->flags!=b->flags)
    return FALSE;
  if(a->start!=b->start||a->end!=b->end)
    return FALSE;
//Dumb hack,,name is first memboer
/*
 * class CRule{
 *   U8 name[STR_LEN];
 * };
 */
  if(a->rule!=b->rule)
    return FALSE;
  return TRUE;
}
ASTSet *ASTSetClone(ASTSet *orig) {
  if(!orig) return NULL;
  ASTSet *ret=GCCAlloc(sizeof(ASTSet)+8*orig->cnt);
  MemCpy(ret,orig,sizeof ASTSet);
  I64 cnt=orig->cnt;
  while(cnt--) {
    ret->body[cnt]=orig->body[cnt];
  }
  return ret;
}
Bool I64SetHasItem(I64Set*dst,I64 a) {
  I64 i;
  if(!dst) return FALSE;
  for(i=0;i!=dst->cnt;i++)
    if(dst->body[i]==a)
      return TRUE;
  return FALSE;
}
extern U0 ASTSetDel(ASTSet *s);
extern U0 ASTDel(AST *a);
U0 ASTDel(AST *a) {
  if(!a) return;
  ASTSetDel(a->nomitive);
  ASTSetDel(a->adjective);
  ASTSetDel(a->conjunction);
  ASTSetDel(a->accusative);
  ASTSetDel(a->dative);
  ASTSetDel(a->ablative);
  ASTSetDel(a->genitive);
  ASTSetDel(a->preposition);
  ASTSetDel(a->measurement);
  ASTSetDel(a->adverb);
  GCFree(a->note);
  GCFree(a->args); //Present in other things
  MemSet(a,0xbe,sizeof AST);
  GCFree(a);
}
U0 ASTSetDel(ASTSet *s) {
  if(!s) return;
  I64 cnt=s->cnt;
//  while(cnt--)
//    ASTDel(s->body[cnt]);
  GCFree(s);
}

U0 DumpASTSet(ASTSet*s) {
  I64 i;
  for(i=0;i!=s->cnt;i++)
    DumpAST(s->body[i]);
}
U0 DumpAST(AST *a) {
  if(!a) return;
  AST *t;
//Dumb hack,rule name is first member.
  "RULE:%s\n",a->rule;
  "FLAGS:%X\n",a->flags;
  DocPrint(DocPut(mem_task),"$$ID,4$$\n");
  if(a->word)
    DocPrint(DocPut(mem_task),"(WORD%s,%d,%n):",a->word->str,a->word_idx,a->prob);
  else if(a->base_expression) {
    DocPrint(DocPut(mem_task),"BASE_EXPR:\n");
    DumpAST(a->base_expression);
    DocPrint(DocPut(mem_task),"BASE_EXPR_END:\n");
  }
  switch(a->act_as_type) {
      break;case AST_VERB: DocPrint(DocPut(mem_task),"VERB\n");
      break;case AST_ADJECTIVE: DocPrint(DocPut(mem_task),"ADJECTIVE\n");
      break;case AST_NOUN:DocPrint(DocPut(mem_task), "NOUN\n");
      break;case AST_OF:DocPrint(DocPut(mem_task), "OF\n");
      break;case AST_CONJUNCTION:DocPrint(DocPut(mem_task),"CONUJUNCTION\n");
      break;case AST_WHERE: DocPrint(DocPut(mem_task),"WHERE\n");
      break;case AST_INFINITIVE: DocPrint(DocPut(mem_task),"INFINITIVE\n");
      break;case AST_ADVERB: DocPrint(DocPut(mem_task),"ADVERB\n");
  }
  if(a->nomitive) {
    DocPrint(DocPut(mem_task),"NOMITIVE:\n");
    DumpASTSet(a->nomitive);
  }
  if(a->accusative) {
    DocPrint(DocPut(mem_task),"ACCUSATIVE:\n");
    DumpASTSet(a->accusative);
  }
  if(a->dative) {
    DocPrint(DocPut(mem_task),"DATIVE:\n");
    DumpASTSet(a->dative);
  }
  if(a->ablative) {
    DocPrint(DocPut(mem_task),"ABLATIVE:\n");
    DumpASTSet(a->ablative);
  }
  if(a->genitive) {
    DocPrint(DocPut(mem_task),"GENITIVE:\n");
    DumpASTSet(a->genitive);
  }
  if(a->preposition) {
    DocPrint(DocPut(mem_task),"PREPOSITION\n");
    DumpASTSet(a->preposition);
  }
  if(a->question) {
    DocPrint(DocPut(mem_task),"QUESTION\n");
    DumpASTSet(a->question);
  }
  if(a->adjective) {
    DocPrint(DocPut(mem_task),"ADJECTIVE\n");
    DumpASTSet(a->adjective);
  }
  if(a->conjunction) {
    DocPrint(DocPut(mem_task),"CONJUNCTION\n");
    DumpASTSet(a->conjunction);
  }
  if(a->measurement) {
    DocPrint(DocPut(mem_task),"MEASURE\n");
    DumpASTSet(a->measurement);
  }
  if(a->adverb) {
    DocPrint(DocPut(mem_task),"ADVERB:\n");
    DumpASTSet(a->adverb);
  }
  DocPrint(DocPut(mem_task),"$$ID,-4$$\n");
}
I64 ASTGetTrieWords(AST *a,CTrie **words) {
  I64 run,max=0,i;
  ASTSet *s;
  if(a->base_expression)
    max=ASTGetTrieWords(a->base_expression,words);
  else  {
    max=a->word_idx;
    if(words) words[a->word_idx]=a->word;
  }
  for(run=0;run<=10;run++) {
    switch(run) {
        break;case 0: s=a->nomitive;
        break;case: s=a->accusative;
        break;case: s=a->dative;
        break;case: s=a->ablative;
        break;case: s=a->genitive;
        break;case: s=a->adjective;
        break;case: s=a->preposition;
        break;case: s=a->conjunction;
        break;case: s=a->measurement;
        break;case: s=a->adverb;
        break;case: s=a->question;
    }
    if(s)
      for(i=0;i!=s->cnt;i++)
        max=MaxI64(max,ASTGetTrieWords(s->body[i],words));
  }
  return max;
}
