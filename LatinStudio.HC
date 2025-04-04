#include "Visual.HC";
F64 line_height=25;
U0 LatinEdDrawIt(CTask *t,CDC *dc) {
  CGlAdvance ga;
  U8 *line,buf[STR_LEN],*en;
  I64 idx,y,idx2,len;
  F64 x,w,ox;
  CTrie *word;
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
  for(line2=oline;line2<=(t->win_bottom-t->win_top)*8/line_height+oline-1;++line2) {
    if (DocGoToLine(doc,line2) && doc->cur_entry->type_u8==DOCT_TEXT)
      line=MStrPrint("%s ",doc->cur_entry->tag); //Add a end of line space
    else //We set DOCF_PLAIN_TEXT,so assume a newline
      line=StrNew(" ");
    y=(line2-oline)*line_height;
    x=0;
    for(idx2=0;line[idx2];) {
      en=SkipWhitespace(line+idx2);
      if(en!=line+idx2) {
        MemCpy(buf,line+idx2,len=en-&line[idx2]);
        buf[len]=0;
        if(odoc->y==line2-1) {
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        } else
	  x+=TTF_RenderText(dc,x,y,buf);
        idx2=en-line;
      } else if(Bt(char_bmp_alpha_numeric,line[idx2])){
        len=0;
        while(line[len+idx2]&&Bt(char_bmp_alpha_numeric,line[len+idx2]))
	  ++len;
        MemCpy(buf,line+idx2,len);
        buf[len]=0;
        if(word=GetWord(buf)) {
	  dc->color=GREEN;
	  ox=x;
	  if(odoc->y==line2-1)
	    x+=DrawSexyWord(dc,16.,x,y,word,buf,odoc->x-idx2);
	  else
	    x+=DrawSexyWord(dc,16.,x,y,word,buf);
	  w=DrawWordInfo(dc,0,0,word,TRUE,buf);
	  DrawWordInfo(dc,(x-ox)/2.+ox-w/2.,y+16.,word,FALSE,buf);
        } else {
	  dc->color=LTRED;
	  if(odoc->y==line2-1)
	    x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
	  else
	    x+=TTF_RenderText(dc,x,y,buf);
        }
        idx2+=len;
      } else {
        len=1;
        buf[0]=line[idx2];
        buf[len]=0;
        dc->color=BLACK;
        if(odoc->y==line2-1)
	  x+=TTF_RenderText(dc,x,y,buf,,,odoc->x-idx2);
        else
	  x+=TTF_RenderText(dc,x,y,buf);
	idx2+=len;
      }
    }
    Free(line);
  }
  DCDel(dummy);
  DocDel(doc);
}
U0 LatinEd(U8 *file) {
  CDoc *doc=DocRead(file,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
  DocClear;
  I64 m,x,y,ww,wh,scroll,lc;
  I64 oldz=ms.pos.z;
  FramePtrAdd("Latin.top",1);
  FramePtrAdd("Latin.doc",doc);
  Fs->draw_it=&LatinEdDrawIt;
  while(TRUE) {
    ww=(Fs->win_right-Fs->win_left)*8/line_height;
    wh=(Fs->win_bottom-Fs->win_top)*8/line_height;
    x=doc->x,y=doc->y;
    DocBottom(doc);
    lc=doc->y;
    doc->x=x,doc->y=y;
    DocRecalc(doc,RECALCt_FIND_CURSOR);
    if(ms.pos.z!=oldz&&0) {
      scroll=FramePtr("Latin.top");
      scroll=ClampI64(scroll+ms.pos.z-oldz,1,MaxI64(1,lc-wh));
      FramePtrSet("Latin.top",scroll);
      oldz=ms.pos.z;
    }
    while(m=ScanMsg(&x,&y)) {
      if(m==MSG_KEY_DOWN) {
        if(x==CH_ESC)
	  goto fin;
        if(!x) {
	  if(y.u8[0]==SC_PAGE_DOWN) {
	    x=wh;
	    while(--x>=0)
 	     EdLineDown(doc);
	  }
	  if(y.u8[0]==SC_PAGE_UP) {
	    x=wh;
	    while(--x>=0)
 	     EdLineUp(doc);
	  }
	  if(y.u8[0]==SC_CURSOR_LEFT) {
	    EdCursorLeft(doc,y);
	  }
	  if(y.u8[0]==SC_CURSOR_RIGHT) 
	    EdCursorRight(doc,y);
	  if(y.u8[0]==SC_CURSOR_UP)
	    EdLineUp(doc,y);
	  if(y.u8[0]==SC_CURSOR_DOWN)
	    EdLineDown(doc,y);
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
    scroll=FramePtr("Latin.top");
    ++doc->y;
    if(scroll>doc->y||doc->y>=scroll+wh) {
	if(doc->y<scroll)
	  scroll=doc->y;
	else
	  scroll=MaxI64(1,doc->y-wh+1);
      FramePtrSet("Latin.top",scroll);
    }
    --doc->y;
    Refresh;
  }
fin:;
  FramePtrDel("Latin.doc");
  FramePtrDel("Latin.top");
  DocWrite(doc);
  DocDel(doc);
}
LatinEd("/Ass.DD");