#define GENF_ALLOW_NEXT 1
#define GENF_DONE 2 //When the generator has exited
#define GENF_DATA_READY 4
class CGenerator {
  U8 (*fptr)(I64);
  CTask *task;
  I64 is_done,flags;
  I64 ret_data;
  I64 input_data;
  I64 user_data,user_data2;
  F64 timeout_tS;
  I64 maximum,generated;
};
U0 GeneratorKill(CGenerator *gen) {
  Kill(gen->task,FALSE);
}
U0 GeneratorYield(I64 value) {
  CGenerator *gen=Fs->user_data;
  gen->ret_data=value;
  gen->generated++;
  if(gen->timeout_tS&&gen->timeout_tS<tS) {
    GeneratorKill(gen);
  }
  if(gen->generated>gen->maximum) {
    GeneratorKill(gen);
  }
  LBts(&gen->flags,GENF_DATA_READY);
  while(!LBtr(&gen->flags,GENF_ALLOW_NEXT)) {
    Fs->wake_jiffy=I64_MAX;
    Yield;
  }
}
CGenerator *GeneratorSelf(CTask *t=NULL) {
  return FramePtr("#Generator",t);
}
U0 GeneratorExit() {
  CGenerator *gen=Fs->user_data;
  LBts(&gen->flags,GENF_DONE);
  Exit;
}
U0 GeneratorTask(CGenerator *gen) {
  Fs->task_end_cb=&GeneratorExit;
  Fs->user_data=gen;
  FramePtrAdd("#Generator",gen); 
  if(gen->fptr)
      (gen->fptr)(gen->input_data);
  LBts(&gen->flags,GENF_DONE);
}
CGenerator *GeneratorNew(U8 (*fptr)(I64),I64 data) {
  static I64 c=0;
//  c=(c+1)%mp_cnt;
  CGenerator *gen=CAlloc(sizeof CGenerator);
  gen->fptr=fptr;
  gen->input_data=data;
  gen->timeout_tS=tS+2.;
  gen->maximum=0x10000;
  gen->task=Spawn(&GeneratorTask,gen,"Generator",c,Fs);
  return gen;
}
Bool GeneratorGet(CGenerator *gen,I64 *res) {
  while(TRUE)  {
    Yield;
    if(LBtr(&gen->flags,GENF_DATA_READY)) {
      LBts(&gen->flags,GENF_ALLOW_NEXT);
      if(res) *res=gen->ret_data;
      return TRUE;
    }
    if(Bt(&gen->flags,GENF_DONE)) {
      Free(gen);
      return FALSE;
    }
    gen->task->wake_jiffy=0;
  }  
}
#if 0
I64 Count(I64 to) {
  I64 i=0;
  for(i=0;i!=to;i++)
    GeneratorYield(i);
}
CGenerator *gen=GeneratorNew(&Count,10);
I64 value;
while(GeneratorGet(gen,&value)) {
  "Igot %d\n",value;
  Sleep(1000);
}
#endif