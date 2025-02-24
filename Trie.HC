#define ALPHABET_SIZE 26
CTask *trie_task = Fs;
class CTrie {
  U8 *str;
  U8 *front_declension;
  U8 *back_declension;
  U8 *translation;
  I64 flags;
  CTrie *branches[ALPHABET_SIZE];
  CTrie *next;
};
CTrie root;
MemSet(&root, 0, sizeof(CTrie));
CTrie *TrieGet(U8 *name, CTrie *of = &root) {
  if (!name) return NULL;
  while (of) {
    if (!*name) {
      while (of && !of->str) of = of->next;
      return of;
    }
    if ('A' <= ToUpper(*name) && ToUpper(*name) <= 'Z') {
      of = of->branches[ToUpper(*name) - 'A'];
      name++;
    } else return NULL;
  }
  return NULL;
}
CTrie *TrieExists(U8 *name, I64 flags) {
  CTrie *t = TrieGet(name);
  while (t) {
    if (t->flags == flags) return t;
    t = t->next;
  }
  return NULL;
}
CTrie *TrieAdd(U8 *name, I64 flags = 0, U8 *translation = NULL) {
  I64 idx;
  CTrie *new = CAlloc(sizeof(CTrie), trie_task);
  CTrie *to = &root, **ins_at = &to->next;
  if (!new) return NULL;
  new->str = StrNew(name, trie_task);
  new->flags = flags;
  if (translation) new->translation = StrNew(translation, trie_task);
  while (*name) {
    if ('A' <= (idx = ToUpper(*name)) && idx <= 'Z') {
      idx -= 'A';
      if (!to->branches[idx]) {
        to->branches[idx] = CAlloc(sizeof(CTrie), trie_task);
        if (!to->branches[idx]) {
          Free(new->str); if (new->translation) Free(new->translation); Free(new); throw('AllocErr');
        }
      }
      to = to->branches[idx]; ins_at = &to->next; name++;
    } else {
      Free(new->str); if (new->translation) Free(new->translation); Free(new); throw('InvChr');
    }
  }
  while (*ins_at) ins_at = &(*ins_at)->next;
  *ins_at = new;
  return new;
}
