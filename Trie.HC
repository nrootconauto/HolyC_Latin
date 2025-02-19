CTask *trie_task=Fs;
class CTrie {
  U8 *str;
  U8 *front_declension;//Optionalaly used 
  U8 *back_declension;//Optionalaly used 
  U8 *translation;
  I64 flags;
  CTrie *branches[26];
  CTrie *next;
};
CTrie root;
MemSet(&root,0,sizeof(CTrie));
CTrie *TrieGet(U8 *name,CTrie *of=&root) {
ent:
  if(!of) return NULL;
  if(!*name) {
    while(!of->str) {
      of=of->next;
      if(!of) return NULL;
    }
    return of;
  }
  if('A'<=ToUpper(*name)<='Z') {
    of=of->branches[ToUpper(*name)-'A'];
    name++;
    goto ent;
  }
  return NULL;
}
CTrie *TrieExists(U8 *name,I64 flags) {
  CTrie *t=TrieGet(name),*ret=t;
  while(t) {
    if(t->flags==flags)
      return t;
    t=t->next;
  }
  return NULL;
}
CTrie *TrieAdd(U8 *name,I64 flags=0,U8 *translation=NULL) {
  I64 idx;
  CTrie *new=CAlloc(sizeof(CTrie),trie_task),*to=&root,**ins_at=&to->next,*new2;
  if(translation) new->translation=StrNew(translation,trie_task);
  new->str=StrNew(name,trie_task);
  new->flags=flags;
  while(*name) {
    if('A'<=(idx=ToUpper(*name))<='Z') {
      idx-='A';
      if(to->branches[idx]) {
	to=to->branches[idx];
      } else{
        new2=CAlloc(sizeof(CTrie),trie_task);
        to->branches[idx]=new2;
	to=new2;
      }
      ins_at=&to->next;
      name++;
    } else if(*name)
      throw('InvChr');
  }
  while(ins_at[0])
    ins_at=&ins_at[0]->next;
  *ins_at=new;
  return new;
};