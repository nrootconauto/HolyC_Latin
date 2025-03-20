#ifndef BAYES_MODE 21
#define BAYES_MODE
#exe{Cd(__DIR__);};
#include "GrammarAST.HC";
#include "Dict.HC";
#define FILE_HASHTABLE_IDENT 'HTabbaTH'
#define FILE_HASHENT_IDENT 'HEnttnEH'
#define FILE_HASH_MASK 124
class CFileHashTable {
  U64 ident;
  U64 cnt;
  U32 body[124];
};
class CFileHashEntry {
  U64 ident;
  I64 value;
  U32 next;
  U8 name[124];
  U8 translation1[128];
  U8 translation2[128];
  U8 translation3[128];
};
I64 FileAllocateBlk(CFile *db) {
  return db->de.size>>BLK_SIZE_BITS;
}
I64 FileIncHashTableCnt(CFile *db,I64 at) {
  CFileHashTable hdr;
  FBlkRead(db,&hdr,at);
  hdr.cnt++;
  FBlkWrite(db,&hdr,at);
  return at;
}
I64 FileNewHashTable(CFile *db,I64 at) {
  CFileHashTable hdr;
  MemSet(&hdr,0,sizeof CFileHashTable);
  hdr.ident=FILE_HASHTABLE_IDENT;
  FBlkWrite(db,&hdr,at);
  return at;  
}
I64 FileHashGet(CFileHashEntry *ret,CFile *db,I64 table,U8 *name) {
  CFileHashTable hdr;
  CFileHashEntry ent;
  I64 new,where;
  U64 hash=HashStr(name);
  FBlkRead(db,&hdr,table);
  if(hdr.ident!=FILE_HASHTABLE_IDENT) {
    throw('File2');
  }
  hash%=FILE_HASH_MASK;
  where=hdr.body[hash];
  if(!where) {
    return NULL;
  }
again:;
  FBlkRead(db,&ent,where);
  if(!StrCmp(name,ent.name)) {
    FBlkRead(db,ret,where);
    return where;
  }
  if(!ent.next)
    return NULL;
  where=ent.next;
  goto again;
}
I64 FileHashAdd(CFile *db,I64 table,U8 *name,I64 value) {
  CFileHashTable hdr;
  CFileHashEntry ent;
  I64 new,where,last;
  U64 hash=HashStr(name);
  FBlkRead(db,&hdr,table);
  if(hdr.ident!=FILE_HASHTABLE_IDENT) {
    throw('File3');
  }
  hash%=FILE_HASH_MASK;
  if(!(where=hdr.body[hash])) {
    new=FileAllocateBlk(db);
    hdr.body[hash]=new;
add:;
    FBlkWrite(db,&hdr,table);
    MemSet(&ent,0,BLK_SIZE);
    StrCpy(ent.name,name);
    ent.value=value;
    ent.ident=FILE_HASHENT_IDENT;
    FBlkWrite(db,&ent,new);
    return new;
  } else {
    FBlkRead(db,&ent,where);
    last=where;
    while(where=ent.next) {
      FBlkRead(db,&ent,where);
      if(ent.ident!=FILE_HASHENT_IDENT) {
        throw('File4');
      }
      last=where;
    }
    new=FileAllocateBlk(db);
    ent.next=new;
    FBlkWrite(db,&ent,last);
    goto add;
  }
}
U0 MakeWordPairsDB(U8 *db_name,U8 *latin,U8 *trans) {
  if(!FileFind(db_name)) {
    CFileHashTable hdr;
    MemSet(&hdr,0,sizeof CFileHashTable);
    hdr.ident=FILE_HASHTABLE_IDENT;
    FileWrite(db_name,&hdr,sizeof(CFileHashTable));
  }
  I64 i,j,reverse;
  U8 buf[STR_LEN];
  latin=TransliterateStr(latin);
  trans=TransliterateStr(trans);
  U8 **latint=TokenizeSentence(latin,NULL,TRUE),*lword;
  U8 **transt=TokenizeSentence(trans,NULL,TRUE),*tword;
  Free(latin);
  Free(trans);
  CFile *file=FOpen(db_name,"w+");
  CFileHashEntry ent; 
  I64 at,at2;
  FBlkRead(file,&hdr,0);
  for(reverse=0;reverse!=2;reverse++) {
    if(reverse)
      SwapI64(&latint,&transt);
    for(i=0;latint[i];i++) {
      lword=latint[i];
      if(!reverse)
        lword=GetBaseWord(lword);
      else
        lword=StrNew(lword);
      if(lword&&!StrICmp(latint[i],lword)) {
	StrUtil(lword,SUF_TO_LOWER);
        for(j=0;transt[j];j++) {
	  tword=transt[j];
	  if(reverse)
	    tword=GetBaseWord(tword);
	  else
	    tword=StrNew(tword);
	  if(tword&&!StrICmp(transt[j],tword)) {
	    StrUtil(tword,SUF_TO_LOWER);
	    if(!reverse)
		FileIncHashTableCnt(file,0);
	    if(!FileHashGet(&ent,file,0,lword)) {
	      at=FileHashAdd(file,0,lword,0);
	      FBlkRead(file,&ent,at);
	      ent.value=FileNewHashTable(file,FileAllocateBlk(file));
	      FBlkWrite(file,&ent,at);
	    }
	    at=ent.value;
	    if(!(at2=FileHashGet(&ent,file,at,tword))) {
	      at2=FileHashAdd(file,at,tword,0);
	      FBlkRead(file,&ent,at2);
	    }
            FileIncHashTableCnt(file,at);
	    FBlkRead(file,&ent,at2);
	    ent.value++;
	    FBlkWrite(file,&ent,at2);
	  }
          Free(tword);
        }
      }
      Free(lword);
    }
  }
  for(i=0;latint[i];i++)
    Free(latint[i]);
  for(i=0;transt[i];i++)
    Free(transt[i]);
  Free(latint);
  Free(transt);
  FClose(file);
}
U0 WordDBFromDict(U8 *db,U8 *latin_json_file) {
  U8 *olatin=FileRead(latin_json_file),*ptr=olatin,*trans;
  CJson *j,*word,*s,*g,*ss,*gs;
  CHeapCtrl *hc,*old=Fs->data_heap;
  I64 inst,sense,gloss;
  U8 buf[STR_LEN];
  try {
    while(TRUE) {
      Fs->data_heap=hc=HeapCtrlInit(NULL,Fs,0);
      j=ParseJson(ptr,&ptr);
      Fs->data_heap=old;
      if(!j) {
        HeapCtrlDel(hc);
        break;
      }
      if(word=GetJsonMember(j,"word")) {
        ss=GetJsonMember(j,"senses");
        if(ss)
	  for(sense=0;s=GetJsonMember(ss,StrPrint(buf,"%d",sense));sense++) {
	    gs=GetJsonMember(s,"glosses");
	    if(gs)
	      for(gloss=0;g=GetJsonMember(gs,StrPrint(buf,"%d",gloss));gloss++) {
	        if(g->type==J_STR) {
		  MakeWordPairsDB(db,word->str,g->str);
	        }
	      }
	    break; //Only do first sense.
	  }
      }
      HeapCtrlDel(hc);
    }
  } catch {
    HeapCtrlDel(hc);
    Fs->data_heap=old;
    PutExcept(TRUE);
  };
  Free(olatin);
}
class CScorePair {
  F64 score;
  U8 word[STR_LEN];
};
I64 ScorePairCmpRev(CScorePair *a,CScorePair *b) {
  if(b->score>a->score)
    return 1;
  if(b->score<a->score)
    return -1;
  return 0;
  
}
U0 WordDBAssignTranslation(U8 *db_name) {
  CFile *db=FOpen(db_name,"w+");
  I64 i,j,tmp,tmp2;
  CFileHashTable root,child,tmph;
  CFileHashEntry roote,childe,tmpe;
  FBlkRead(db,&root,0);
  F64 all,word1,word2,prob;
  F64 best_prob;
  CScorePair scores[4];
  I64 score_ptr;
  U8 best_word[STR_LEN];
  all=root.cnt;
  for(i=0;i<FILE_HASH_MASK;i++) {
    if(tmp=root.body[i]) {
again1:
      best_prob=-1;
      StrCpy(best_word,"");

      FBlkRead(db,&roote,tmp);
      FBlkRead(db,&child,roote.value);
      word1=ToF64(child.cnt)/all;
	MemSet(scores,0,sizeof(CScorePair)*4);
      for(j=0;j<FILE_HASH_MASK;j++) {
        if(tmp2=child.body[j]) {
again2:;
	  FBlkRead(db,&childe,tmp2);
	  if(FileHashGet(&tmpe,db,0,childe.name)){
	    FBlkRead(db,&tmph,tmpe.value); //Read pointer of sub-hashtable
	    word2=ToF64(tmph.cnt)/all;
	  }
	  prob=(word1*(ToF64(childe.value)/ToF64(roote.value)))/word2;// Bayes Theorem
	  scores[3].score=prob;
	  StrCpy(scores[3].word,tmpe.name);
	  QSort(scores,4,sizeof(CScorePair),&ScorePairCmpRev);
	  if(childe.next) {
	    tmp2=childe.next;
	    goto again2;
	  }
        }
      }
      StrCpy(roote.translation1,scores[0].word);
      StrCpy(roote.translation2,scores[1].word);
      StrCpy(roote.translation3,scores[2].word);
      FBlkWrite(db,&roote,tmp);

      Yield;
      if(roote.next) {
        tmp=roote.next;
        goto again1;
      }
    }

  }
  FClose(db);
}
U8 *BibleVerseVulgate(U8 *book,I64 chap,I64 verse,U8 *vpath="Vulgate/Vulgate.DD") {
  U8 *path=MStrPrint("%s/%s %d/%s,%d:%d",book,book,chap,book,chap,verse);
  CDoc *doc=DocRead(vpath),*copy;
  CDocEntry *tr,*ids,*ide;
  if(DocTreeFind(doc,path,&tr,&ids,&ide)) {
    copy=DocCopy(doc,ids,ide);
  } else
    copy=NULL;
  Free(path);
  DocDel(doc);
  if(copy) path=DocSave(copy);
  else return NULL;
  DocDel(copy);
  return path;
}
U0 WordDBVulgate(U8 *db,U8 *book="Genesis") { 
  I64 i,k;
  U8 *latin,*trans;
  for(i=1;TRUE;i++) {
    for(k=1;TRUE;k++) {
      latin=BibleVerseVulgate(book,i,k,"Vulgate/Vulgate.DD");
      trans=BibleVerseVulgate(book,i,k,"Vulgate/VulgateTrans.DD");
      if(latin&&trans) {
        "%s,%s\n",latin,trans;
        MakeWordPairsDB(db,latin,trans);
        Free(latin),Free(trans);
      } else {
        Free(latin),Free(trans);
        break;
      }
    }
    if(k==1)
      break;
  }
}
//Poems to the Pee Pee God(?),writen by Priapus
U0 WordDBPeenisumPoems(U8 *db,U8 *dirp="Peenisum") {
  dirp=MStrPrint("%s/*.DD*",dirp);
  CDirEntry *dir=FilesFind(dirp,FUF_JUST_FILES),*e;
  I64 l;
  U8 *latin,*tran;
  for(e=dir;e;e=e->next) {
    for(l=1;TRUE;l+=2) {
      latin=DocLineRead(e->full_name,l);
      tran=DocLineRead(e->full_name,l+1);
      if(!latin||!tran) {
        Free(latin),Free(tran);
	break;
      }
      MakeWordPairsDB(db,latin,tran);
      Free(latin),Free(tran);
    }
  }
  DirTreeDel(dir);
  Free(dirp);
}
U8 *WordDBGetTranslation(U8 *db_name="Words.DB",U8 *word) {
  U8 *tmp=GetBaseWord(word);
  if(tmp)
     word=tmp;
  else
    word=StrNew(word);
  StrUtil(word,SUF_TO_LOWER);
  CFile *f=FOpen(db_name,"r");
  U8 *ret=NULL;
  U8 buf[3*STR_LEN];
  CFileHashEntry hent;
  if(!FileHashGet(&hent,f,0,word)) {
    goto fin;
  }
  StrPrint(buf,"%s",hent.translation1);
  if(hent.translation2[0])
    CatPrint(buf,",%s",hent.translation2);
  if(hent.translation3[0])
    CatPrint(buf,",%s",hent.translation3);
  ret=StrNew(buf);
fin:
  Free(word);
  FClose(f);
  return ret;
}
//Del("Words3.DB");
if(!FileFind("Words.DB")) {
  WordDBFromDict("Words.DB","Latin.json");
  //WordDBVulgate("Words.DB","Genesis");
  //WordDBVulgate("Words.DB","Exodus");
  WordDBPeenisumPoems("Words.DB");
  WordDBAssignTranslation("Words.DB");
}
#if __CMD_LINE__
//WordDBPeenisumPoems("Words.DB");
//WordDBAssignTranslation("Words.DB");
"%s\n",WordDBGetTranslation("Words.DB","esca");
//"%s\n",WordDBGetTranslation("Words.DB","plantaria");
#endif
#endif