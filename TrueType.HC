U8 *TTF_GetTablePtr(U32 key,U8 *f,I64 *len=NULL) {
  I64 tcnt=(f+4)(U16*)[0];
  U32 *ballsack=f+12;
  while(--tcnt>=0) {
    if(*key==*ballsack) {
      if(len) *len=ballsack[3];
      return f+ballsack[2];
    }
    ballsack(U8*)+=16;
  }
  return NULL;
}
U0 TTF_HMetrics(I64 g,U8* f,I64 *advance,I64 *left_bear) {
  U8 *hmtx=TTF_GetTablePtr("hmtx",f),*head=TTF_GetTablePTr("hhea",f);
  I64 long_hmtx=(head+34)(U16*)[0];
  I64 en;
  if(advance) *advance=0;
  if(left_bear) *left_bear=0;
  if(!htmx) return;
  if (g<long_hmtx) {
//Forward [1,2,3.........]
    hmtx+=4*glyph;
    if(advance) *advance=*(hmtx(I16*));
    if(left_bear) *left_bear=hmtx(I16*)[1];
    return 0;
  } else {
//Backwars [.............7,8,9]
    en=long_hmtx*4;
    if(en<4) return;
    if(advance) *advanceWidth=(hmtx+en-4)(I16*)[0];
    if(left_bear) *left_bear=(hmtx+en-2*(g-long_hmtx))(I16*)[0];
  }
}