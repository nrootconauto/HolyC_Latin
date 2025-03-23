#ifndef GC_HH
#define GC_HH 21
#define GC_MASK 0x7fff
CQue gc_heads[GC_MASK+1];
CQue gc_goods[GC_MASK+1];
CQue gc_to_check;

CTask *gc_mem_heap=Fs;
F64 gc_next=tS;
class CGCPtr:CQue {
  I32 marked;
  I32 handled;
  CGCPtr *replace_with;
  U0 start;
};
U64 HashPtr(I64 p) {
  p>>=3;
  I64 h=21;
  I64 i;
  for(i=0;i!=8;i++) {
    h*=37;
    h+=(p>>(i*8))&0xff;
  }
  return h;
}
Bool GCMarkPtr0(CGCPtr *ptr) {
  static I64 depth=0;
//MAlloced ptrs are aligned
  if(!ptr||ptr&0b111)
	return FALSE;
  I64 bucket=HashPtr(ptr)&GC_MASK;
  --ptr;
  I64 len;
  U8 **flat;
  CGCPtr  *head=&gc_heads[bucket],*cur;
  for(cur=head->next;cur!=head;cur=cur->next) {
    if(ptr==cur) {
      if(ptr->marked++ ==0&&!ptr->handled) {
	if(++depth<=128) {
	  QueRem(ptr);
	  QueIns(ptr,&gc_goods[bucket]);
	  len=MSize(ptr)-sizeof(CGCPtr);
	  ptr->handled=TRUE;
	  flat=ptr+1;
	  while((len-=8)>=0) {
	    GCMarkPtr0(*flat);
	    ++flat;
	  }
          --depth;
	  return FALSE; //Already handled
        }
	QueRem(ptr);
	QueIns(ptr,gc_to_check.last);
        --depth;
	return TRUE;
      }
    }
  }
  return FALSE;
}
Bool GCMarkPtr(U8 **flat,I64 l) {
  Bool r=FALSE;
  while((l-=8)>=0) {
    r|=GCMarkPtr0(*flat);
    flat++;
  }
  return r;
}
U0 ScanAllMem(CTask *for_task,U8 *head2,Bool(*scan)(U8*,I64)) {
  CHashGlblVar *gv;
  CExcept *cur_ex;
  I64 len;
  U8 **flat,repeat;
  CGCPtr *dummy,*head,*cur,*next;
  I64 bucket=for_task->hash_table->mask+1;
  while(--bucket>=0) {
    gv=for_task->hash_table->body[bucket];
    while(gv) {
      if(gv->type&HTT_GLBL_VAR&&gv->data_addr) {
        len=gv->size;
        flat=gv->data_addr;
        if(flat!=&gc_heads&&flat!=&gc_goods&&flat!=&gc_to_check)
	  scan(flat,len);
      }
      gv=gv->next;
    }
  }
  flat=for_task;
  len=sizeof(CTask);
  scan(flat,len);

  for(cur_ex=for_task->next_except;cur_ex!=&for_task->next_except;cur_ex=cur_ex->next) {
    flat=cur_ex;
    len=MSize(cur_ex);
    scan(flat,len);
  }
  flat=for_task->stk;
  len=MSize(flat);
  scan(flat,len);

  //New to checks are added at the end,so dont worry about new ones being added
  for(cur=gc_to_check.next;cur!=&gc_to_check;cur=next) {
    dummy=cur+1;
    cur->marked=0;
    cur->handled=0;
    scan(cur,MSize(cur));
    QueRem(cur);
    bucket=HashPtr(cur+1)&GC_MASK;
    QueIns(cur,&gc_goods[bucket]);
    next=gc_to_check.next;
  }
}
U0 GCTask(CTask *for_task) {
  U8 **flat;
  I64 len;
  Bool repeat;
  I64 bucket,total;
  F64 old_tS=tS;
  CGCPtr *head,*cur,*next;

  while(TRUE) {
    gc_next=tS-old_tS+1.1;
    Sleep(1000+(tS-old_tS)*1000.);
    old_tS=tS;
    bucket=GC_MASK+1;
    while(--bucket>=0) {
      head=&gc_heads[bucket];
      for(cur=head->next;cur!=head;cur=cur->next) {
        cur->marked=0,cur->handled=0;
      }
    }

    ScanAllMem(for_task,&gc_heads,&GCMarkPtr);

    bucket=GC_MASK+1;
    while(--bucket>=0) {
      head=&gc_heads[bucket];
      QueDel(head);
      QueInit(head);
    }
    bucket=GC_MASK+1;
 
    while(--bucket>=0) {
      if(QueCnt(&gc_goods[bucket])) {
	head=&gc_heads[bucket];
	head->next=gc_goods[bucket].next;
	head->last=gc_goods[bucket].last;
	head->next->last=head;
	head->last->next=head;
      }
      QueInit(&gc_goods[bucket]);
    }
  }
}

U8 *GCCAlloc(I64 sz) {
  if(gc_next<tS)
    Yield;
  CGCPtr *p=CAlloc(sz+sizeof(CGCPtr),gc_mem_heap);
  QueIns(p,gc_heads[HashPtr(p+1)&GC_MASK].next);
  return p+1;
}
U8 *GCStrNew(U8 *s) {
  if(!s) return NULL;
  if(gc_next<tS)
    Yield;
  U8 *ret=GCCAlloc(StrLen(s)+1);
  StrCpy(ret,s);
  return ret;
}
U8 *GCMAllocIdent(CGCPtr *s) {
  if(!s) return NULL;
  if(gc_next<tS)
    Yield;
  I64 l;
  U8 *ret=GCCAlloc(l=MSize(s-1)-sizeof(CGCPtr));
  MemCpy(ret,s,l);
  return ret;
}

U0 GCInit() {
  I64 i=GC_MASK+1;
  while(--i>=0) {
    QueInit(&gc_heads[i]);
    QueInit(&gc_goods[i]);
  }
  QueInit(&gc_to_check);
  Spawn(&GCTask,Fs,"Gabbage Collector",,Fs);
}
I64 GCMSize(CGCPtr *p) {
  if(!p) return 0;
  return MSize(p-1);
}
U0 GCFree(CGCPtr *p) {
  if(!p) return;
  QueRem(p-1);
  Free(p-1);
  if(gc_next<tS)
    Yield;
}

GCInit;
#endif