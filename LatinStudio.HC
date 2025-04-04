#include "Visual.HC";
F64 line_height=25;
U0 LatinEdDrawIt(CTask *t,CDC *dc) {
  CGlAdvance ga;
  U8 *line;
  I64 idx,y;
  F64 x,w;
  CDoc *doc=FramePtr("Latin.doc",t),*odoc=doc;
  CDC *dummy=DCNew(1,1);
  if(!doc)
    return;
  line=DocSave(doc,&x);
  doc=DocNew;
  DocLoad(doc,line,x);
  Free(line);
  dc->color=BLACK;
  I64 oline=FramePtr("Latin.top",t),line2;
  for(line2=oline;line2<=(t->win_bottom-t->win_top)*8/line_height-oline-1;++line2) {
    if (DocGoToLine(doc,line2) && doc->cur_entry->type_u8==DOCT_TEXT)
      line=MStrPrint("%s ",doc->cur_entry->tag,mem_task); //Add a end of line space
    else if(DocGoToLine(doc,line2) && doc->cur_entry->type_u8==DOCT_NEW_LINE)
      line=StrNew("\n",mem_task);
    else 
      break;
    y=(line2-oline)*line_height;
    x=0;
    if(line2-oline==odoc->y)
      TTF_RenderText(dc,x,y,line,,,odoc->x);
    else
      TTF_RenderText(dc,x,y,line,,,-1);
    Free(line);
  }
  DCDel(dummy);
  DocDel(doc);
}
U0 LatinEd(U8 *file) {
  CDoc *doc=DocNew(file);
  doc->flags|=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
  DocClear;
  I64 m,x,y;
  FramePtrAdd("Latin.doc",doc);
  FramePtrAdd("Latin.top",1);
  Fs->draw_it=&LatinEdDrawIt;
  while(TRUE) {
    while(m=ScanMsg(&x,&y)) {
      if(m==MSG_KEY_DOWN) {
	if(x==CH_ESC)
	  goto fin;
        if(!x) {
	  if(y.u8[0]==SC_CURSOR_LEFT)
	    EdCursorLeft(doc);
	  if(y.u8[0]==SC_CURSOR_RIGHT) 
	    EdCursorRight(doc);
	  if(y.u8[0]==SC_CURSOR_UP)
	    EdLineUp(doc);
	  if(y.u8[0]==SC_CURSOR_DOWN)
	    EdLineDown(doc);
        } else if(x==CH_BACKSPACE) {
	  EdCursorLeft(doc);
	  EdCharDel(doc);
        } else if(Bt(char_bmp_displayable,x&0xffff)) {
  	  EdCharIns(x,y,doc);
        } else if(x=='\n') {
  	  EdCharIns(x,y,doc);
	}
      }
    }
    Refresh;
  }
fin:;
  FramePtrDel("Latin.top");
  FramePtrDel("Latin.doc");
  DocWrite(doc);
  DocDel(doc);
}
LatinEd("/Ass.DD");