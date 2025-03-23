#ifndef ANNOTATE
#define ANNOTATE 21
#include "RuleSet.HC";
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
I64 PosSort(AST *a,AST *b) {
  return a->start-b->start;
} 
I64 NextNumber() {
  I64 ret=FramePtr("AST.Number");
  FramePtrSet("AST.Number",ret+1);
  return ret;
}
extern U0 NumberAST0(AST *a,Bool real=FALSE);
U0 NumberASTSet(ASTSet *a,Bool real=FALSE) {
  if(!a) return;
  ASTSet *clone=GCMAllocIdent(a);
  QSortI64(clone->body,clone->cnt,&PosSort);
  I64 i;
  for(i=0;i!=clone->cnt;i++)
    NumberAST0(clone->body[i],real);
}
U0 NumberAST0(AST *a,Bool real=FALSE) {
  ASTSet *clone=GCMAllocIdent(a->args);
  AST *have;
  Bool verb1,verb2;
  if(a->base_expression)
    clone=I64SetAdd(clone,a->base_expression);
  QSortI64(clone->body,clone->cnt,&PosSort);
  I64 i;
  if(real) {
    a->number=NextNumber;
  }

  verb1=a->raw_type==AST_VERB||a->raw_type==AST_VERB;
  if(have=a->base_expression) {
    verb2=have->raw_type==AST_VERB||have->raw_type==AST_VERB;
  } else
    verb2=FALSE;

  if(verb1||verb2) {
    NumberASTSet(a->nomitive,TRUE);
    if(verb2)
      a->base_expression->number=NextNumber;
    else
      a->number=NextNumber;
    NumberASTSet(a->accusative,TRUE);
    NumberASTSet(a->genitive,TRUE);
    NumberASTSet(a->dative,TRUE);
    NumberASTSet(a->ablative,TRUE);
  } else {
    for(i=0;i!=clone->cnt;i++) {
      have=clone->body[i];
      if(have!=a)
        NumberAST0(have,FALSE);
    }
  }
fin:
}
U0 NumberAST(AST *a) {
  FramePtrAdd("AST.Number",1);
  NumberAST0(a);
  FramePtrDel("AST.Number");
}
#endif