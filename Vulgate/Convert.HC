#exe{Cd(__DIR__);};;
#include"../Utils.HC";
U0 MakeDolDocVulgateBook(CDoc *to,U8 *name,U8 *in) {
  CDoc *idoc=DocRead(in,DOCF_PLAIN_TEXT|DOCF_NO_CURSOR|DOCF_PLAIN_TEXT_TABS);
  DocPrint(to,"$$TR-C,\"%Q\"$$\n$$ID,2$$\n",name);
  I64 line;
  U8 *ln,*res,*ptr,c;
  I64 chap,verse,last_chap=0;
  for(line=1;TRUE;line++) {
    if (DocGoToLine(idoc,line) && idoc->cur_entry->type_u8==DOCT_TEXT)
      res=StrNew(idoc->cur_entry->tag);
    else if(DocGoToLine(idoc,line) && idoc->cur_entry->type_u8==DOCT_NEW_LINE)
      res=StrNew("\n");
    else break;
    if(*res=='{') {
      ptr=StrScan(res,"{%d:%d}",&chap,&verse);
      if(last_chap!=chap) {
        if(last_chap)
          DocPrint(to,"$$ID,-2$$\n");
        DocPrint(to,"$$TR-C,\"%s %d\"$$$$ID,2$$\n",name,chap);
	last_chap=chap;
      }
        DocPrint(to,"$$TR-C,\"%s,%d:%d\"$$\n$$ID,2$$",name,chap,verse);
	while(c=Transliterate(ReadUTF8(ptr,&ptr))) {
	  DocPrint(to,"%c",c);
          if(*ptr==0)
	    break;
        }
	DocPrint(to,"$$ID,-2$$\n");  
    }
    Free(res);
   
  }
  DocPrint(to,"$$ID,-4$$\n"); //-2 for chapter,-2 for book
  DocDel(idoc);
}
CDoc *vulgate=DocNew("Vulgate.DD");
DocMax(vulgate);
MakeDolDocVulgateBook(vulgate,"Genesis","Genesis.DD");
MakeDolDocVulgateBook(vulgate,"Exodus","Exodus.DD");
/*MakeDolDocVulgateBook(vulgate,"Leviticus","Leviticus.DD");
MakeDolDocVulgateBook(vulgate,"Numbers","Numbers.DD");
MakeDolDocVulgateBook(vulgate,"Deuteronomy","Deuteronomy.DD");
MakeDolDocVulgateBook(vulgate,"Joshua","Joshua.DD");
MakeDolDocVulgateBook(vulgate,"Judges","Judges.DD");
MakeDolDocVulgateBook(vulgate,"Ruth","Ruth.DD");
MakeDolDocVulgateBook(vulgate,"1 Samuel","Samuel1.DD");
MakeDolDocVulgateBook(vulgate,"2 Samuel","Samuel2.DD");
MakeDolDocVulgateBook(vulgate,"1 Kings","Kings1.DD");
MakeDolDocVulgateBook(vulgate,"2 Kings","Kings2.DD");
MakeDolDocVulgateBook(vulgate,"1 Chronicles","Chronicles1.DD");
MakeDolDocVulgateBook(vulgate,"2 Chronicles","Chronicles2.DD");
MakeDolDocVulgateBook(vulgate,"Ezra","Ezra.DD");
MakeDolDocVulgateBook(vulgate,"Nehemiah","Nehemiah.DD");
MakeDolDocVulgateBook(vulgate,"Esther","Esther.DD");
MakeDolDocVulgateBook(vulgate,"Job","Job.DD");
MakeDolDocVulgateBook(vulgate,"Psalms","Psalms.DD");
MakeDolDocVulgateBook(vulgate,"Proverbs","Proverbs.DD");
MakeDolDocVulgateBook(vulgate,"Ecclesiastes","Ecclesiastes.DD");
MakeDolDocVulgateBook(vulgate,"Song of Songs","SongOfSongs.DD");
MakeDolDocVulgateBook(vulgate,"Isaiah","Isaiah.DD");
MakeDolDocVulgateBook(vulgate,"Jeremiah","Jeremiah.DD");
MakeDolDocVulgateBook(vulgate ,"Lamentations","Lamentations.DD");*/
DocWrite(vulgate);
DocDel(vulgate);
CDoc *vulgate_trans=DocNew("VulgateTrans.DD");
DocMax(vulgate_trans);
MakeDolDocVulgateBook(vulgate_trans,"Genesis","GenesisTrans.DD");
MakeDolDocVulgateBook(vulgate_trans,"Exodus","ExodusTrans.DD");
DocWrite(vulgate_trans);
DocDel(vulgate_trans);

