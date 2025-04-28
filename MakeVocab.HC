#ifndef BAYES_MODE
#define BAYES_MODE 21
#exe{Cd(__DIR__);};
#include "GrammarAST.HC";
#define FILE_HASHTABLE_IDENT 'HTab'
#define FILE_HASHENT_IDENT 'HEnt'
#define FILE_HASH_MASK 62
class CFileHashTable {
  U32 ident;
  U32 cnt;
  U32 body[62];
}; //BLK_SIZE/2
class CFileHashEntry {
  U32 ident;
  U32 value;
  U32 next;
  U64 flags;
  U8 name[59];
  U8 translation1[59];
  U8 translation2[59];
  U8 translation3[59];
};
U0 DBInit(U8 *db_name) {
  if(!FileFind(db_name)) {
    CFileHashTable hdr['Z'-'A'+1];
    MemSet(&hdr,0,sizeof(CFileHashTable)*26);
    I64 i;
    for(i=0;i!=26;i++)
      hdr[i].ident=FILE_HASHTABLE_IDENT;
    FileWrite(db_name,&hdr,sizeof(CFileHashTable)*26);
  }
}

U0 FHalfBlkWrite(CFile *db,U8 *data,I64 blk) {
  U8 full[BLK_SIZE];
  MemSet(full,0,BLK_SIZE);
  FBlkRead(db,full,blk>>1);
  if(blk&1)
    MemCpy(full+BLK_SIZE/2,data,BLK_SIZE/2);
  else
    MemCpy(full,data,BLK_SIZE/2);
  FBlkWrite(db,full,blk>>1);
}
U0 FHalfBlkRead(CFile *db,U8 *data,I64 blk) {
  U8 full[BLK_SIZE];
  FBlkRead(db,full,blk>>1);
  if(blk&1)
    MemCpy(data,full+BLK_SIZE/2,BLK_SIZE/2);
  else
    MemCpy(data,full,BLK_SIZE/2);
}

I64 FileAllocateBlk(CFile *db) {
  I64 final=db->de.size>>BLK_SIZE_BITS;
  if(!final) return 0;
  U32 dumb[BLK_SIZE/4];
  FHalfBlkRead(db,dumb,final<<1-1);
  if(dumb[0]==0)
    return final<<1-1;
  return final<<1;
}
I64 FileIncHashTableCnt(CFile *db,I64 at) {
  CFileHashTable hdr;
  FHalfBlkRead(db,&hdr,at);
  hdr.cnt++;
  FHalfBlkWrite(db,&hdr,at);
  return at;
}
I64 FileNewHashTable(CFile *db,I64 at) {
  CFileHashTable hdr;
  MemSet(&hdr,0,sizeof CFileHashTable);
  hdr.ident=FILE_HASHTABLE_IDENT;
  FHalfBlkWrite(db,&hdr,at);
  return at;  
}
I64 FileHashGet(CFileHashEntry *ret,CFile *db,I64 table,U8 *name,I64 inst=1) {
  CFileHashTable hdr;
  CFileHashEntry ent;
  I64 new,where;
  U64 hash=HashStr(name);
//Root table have A,B,C...Z entries
  if(table==0) {
    if('A'<=ToUpper(*name)<='Z')
      table+=ToUpper(*name)-'A';
  }
  FHalfBlkRead(db,&hdr,table);
  if(hdr.ident!=FILE_HASHTABLE_IDENT) {
    throw('File2');
  }
  hash%=FILE_HASH_MASK;
  where=hdr.body[hash];
  if(!where) {
    return NULL;
  }
again:;
  FHalfBlkRead(db,&ent,where);
  if(!StrCmp(name,ent.name)) {
    if(--inst==0) {
      FHalfBlkRead(db,ret,where);
      return where;
    }
  }
  if(!ent.next)
    return NULL;
  where=ent.next;
  goto again;
}
I64 FileHashAdd(CFile *db,I64 table,U8 *name,I64 value) {
  CFileHashTable hdr;
  CFileHashEntry ent;
  I64 new,where;
  I64 next=0;
  U64 hash=HashStr(name);
//Root table have A,B,C...Z entries
  if(table==0) {
    if('A'<=ToUpper(*name)<='Z')
      table+=ToUpper(*name)-'A';
  }
  FHalfBlkRead(db,&hdr,table);
  if(hdr.ident!=FILE_HASHTABLE_IDENT) {
    throw('File3');
  }
  hash%=FILE_HASH_MASK;
  if(!(where=hdr.body[hash])) {
    new=FileAllocateBlk(db);
    hdr.body[hash]=new;
add:;
    FHalfBlkWrite(db,&hdr,table);
    MemSet(&ent,0,BLK_SIZE/2);
    StrCpy(ent.name,name);
    ent.next=next;
    ent.value=value;
    ent.ident=FILE_HASHENT_IDENT;
    FHalfBlkWrite(db,&ent,new);
    return new;
  } else {
    FHalfBlkRead(db,&ent,where);
    new=FileAllocateBlk(db);
    next=where;
    hdr.body[hash]=new;
    goto add;
  }
}
U0 MakeWordPairsDB(U8 *db_name,U8 *latin,U8 *trans) {
  DBInit(db_name);
  CFileHashTable hdr;
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
	      FHalfBlkRead(file,&ent,at);
	      ent.value=FileNewHashTable(file,FileAllocateBlk(file));
	      FHalfBlkWrite(file,&ent,at);
	    }
	    at=ent.value;
	    if(!(at2=FileHashGet(&ent,file,at,tword))) {
	      at2=FileHashAdd(file,at,tword,0);
	      FHalfBlkRead(file,&ent,at2);
	    }
            FileIncHashTableCnt(file,at);
	    FHalfBlkRead(file,&ent,at2);
	    ent.value++;
	    FHalfBlkWrite(file,&ent,at2);
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
  DBInit(db);
  CFile *dbf=FOpen(db,"w+");
  FileHashAdd(dbf,0,"DB,Version",1);
  FClose(dbf);
  U8 *olatin=FileRead(latin_json_file),*ptr=olatin,*trans;
  I64 lines=StrOcc(olatin,'\n'),line=0;
  CJson *j,*word,*s,*g,*ss,*gs;
  CHeapCtrl *hc,*old=Fs->data_heap;
  I64 inst,sense,gloss,at;
  U8 buf[STR_LEN];
  I64 last_cnt=0;
  F64 t=tS,per_sec=1.,ti=t;
  progress1_t0=ti;
  try {
    while(TRUE) {
      Fs->data_heap=hc=HeapCtrlInit(NULL,Fs,0);
      at=ptr-olatin;
      j=ParseJson(ptr,&ptr);
      Fs->data_heap=old;
      if(!j) {
        HeapCtrlDel(hc);
        break;
      }
      if(word=GetJsonMember(j,"word")) {
        StrPrint(buf,"JsonPos,%s",word->str);
	dbf=FOpen(db,"w+");
	FileHashAdd(dbf,0,buf,at);
        FClose(dbf);
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
      progress1_max=lines;
      progress1=++line;
      if(tS>1.+t) {
        per_sec+=line-last_cnt;
	per_sec/=2.;
        progress1_tf=(lines-line)/per_sec+ti;
	t=tS;
	last_cnt=line;
      }
    }
  } catch {
    HeapCtrlDel(hc);
    Fs->data_heap=old;
    PutExcept(TRUE);
  };
  ProgressBarsRst;
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
  FHalfBlkRead(db,&root,0);
  F64 all,word1,word2,prob;
  F64 best_prob;
  CScorePair scores[4];
  I64 score_ptr;
  I64 root_letter;
  U8 best_word[STR_LEN];
  all=0;
  for(root_letter='A';root_letter<='Z';++root_letter) {
    FHalfBlkRead(db,&root,root_letter-'A');
    all+=root.cnt;
  }
  for(root_letter='A';root_letter<='Z';++root_letter) {
    FHalfBlkRead(db,&root,root_letter-'A');
    for(i=0;i<FILE_HASH_MASK;i++) {
      if(tmp=root.body[i]) {
again1:
        best_prob=-1;
        StrCpy(best_word,"");

        FHalfBlkRead(db,&roote,tmp);
        if(StrOcc(roote.name,'.'))
	  goto next;
        if(StrOcc(roote.name,','))
	  goto next;
        FHalfBlkRead(db,&child,roote.value);
        word1=ToF64(child.cnt)/all;
        MemSet(scores,0,sizeof(CScorePair)*4);
        for(j=0;j<FILE_HASH_MASK;j++) {
	  if(tmp2=child.body[j]) {
again2:;
	    FHalfBlkRead(db,&childe,tmp2);
	    if(FileHashGet(&tmpe,db,0,childe.name)){
	      FHalfBlkRead(db,&tmph,tmpe.value); //Read pointer of sub-hashtable
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
        FHalfBlkWrite(db,&roote,tmp);
next:;
        if(roote.next) {
	  tmp=roote.next;
	  goto again1;
        }
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
U8 *WordDBGetTranslation(U8 *db_name=__DIR__"/Words.DB",U8 *word,I64 which=0) {
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
  CTrie *trie;
  if(!FileHashGet(&hent,f,0,word))
    goto fin;
  if(which==0)
    ret=MStrPrint("%s",hent.translation1);
  else if(which==1&&hent.translation2[0])
    ret=MStrPrint("%s",hent.translation2);
  else if(which==2&&hent.translation3[0])
    ret=MStrPrint("%s",hent.translation3);
  else
    ret=NULL;
fin:
  Free(word);
  FClose(f);
  return ret;
}
U0 WordDBSetTranslation(U8 *db_name=__DIR__"/Words.DB",U8 *word,U8 *trans,I64 which=0) {
  U8 *tmp=GetBaseWord(word);
  CTrie *trie;
  if(tmp)
     word=tmp;
  else
    word=StrNew(word);
  StrUtil(word,SUF_TO_LOWER);
  CFile *f=FOpen(db_name,"w+");
  I64 blk;
  CFileHashEntry hent;
  if(!(blk=FileHashGet(&hent,f,0,word)))
    goto fin;
  if(which==0)
    StrCpy(hent.translation1,trans);
  else if(which==1)
    StrCpy(hent.translation2,trans);
  else if(which==2)
    StrCpy(hent.translation3,trans);
  FHalfBlkWrite(f,&hent,blk);
  for(trie=TrieGet(tmp);trie;trie=trie->next) {
    Free(trie->translation);
    trie->translation=StrNew(trans,mem_task);
  }
fin:
  Free(word);
  FClose(f);
}


I64 DBVersion(U8 *db_name=__DIR__"/Words.DB") {
  CFile *db=FOpen(db_name,"r");
  CFileHashEntry ent;
  I64 ver=0;
  if(FileHashGet(&ent,db,0,"DB,Version")) {
    ver=ent.value;
  }
  FClose(db);
  return ver;
}
I64 DBValue(U8 *w,U8 *db_name=__DIR__"/Words.DB",I64 which=1) {
  CFile *db=FOpen(db_name,"r");
  if(!db) return 0;
  CFileHashEntry ent;
  I64 ver=0;
  if(FileHashGet(&ent,db,0,w,which)) {
    ver=ent.value;
  }
  FClose(db);
  return ver;

}
//Del("Words3.DB");
if(FileFind(__DIR__"/Words.DB.Z"))
  Unzip(__DIR__"/Words.DB.Z");
if(!FileFind(__DIR__"/Words.DB")||DBVersion!=1) {
  WordDBFromDict(__DIR__"/Words.DB",__DIR__"/Latin.json");
  //WordDBVulgate(__DIR__"/Words.DB"","Genesis");
  //WordDBVulgate(__DIR__"/Words.DB"","Exodus");
  WordDBPeenisumPoems(__DIR__"/Words.DB");
  WordDBAssignTranslation(__DIR__"/Words.DB");
}
#if __CMD_LINE__
//WordDBPeenisumPoems(__DIR__"/Words.DB");
//WordDBAssignTranslation(__DIR__"/Words.DB");
"%s\n",WordDBGetTranslation(__DIR__"/Words.DB","esca");
//"%s\n",WordDBGetTranslation(__DIR__"/Words.DB"","plantaria");
#endif
#endif