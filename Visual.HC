#ifndef VISUAL_HH
#define VISUAL_HH 21
#exe {Cd(__DIR__);};
#include "Annotate.HC";
#include "FileBMP.HC";
U0 CalcBezier(CD3I32 *point,CD3I32*l,CD3I32 *cent,CD3I32 *r) {
  point->x=2.*cent->x-l->x/2.-r->x/2.;
  point->y=2.*cent->y-l->y/2.-r->y/2.;
}
//Returns maximum y
F64 GrPreciseBezier(CDC *dc,CD3I32*ctrls,F64 *highest_x_pos=NULL) {
  F64 x=ctrls[2].x,y=ctrls[2].y,x2,y2,step;
  F64 max_y=y;
  F64 max_x=x;
  for(step=1/100.;step<=1;step+=1./100.) {
    x2=ctrls[0].x*step`2+ctrls[1].x*2*step*(1-step)+ctrls[2].x*(1-step)`2;
    y2=ctrls[0].y*step`2+ctrls[1].y*2*step*(1-step)+ctrls[2].y*(1-step)`2;
    GrLine3(dc,x,y,0,x2,y2,0);
    x=x2,y=y2;
    if(y>=max_y) {
      max_y=y;
      max_x=x;
    }
  }
  if(highest_x_pos) *highest_x_pos=max_x;
  return max_y;
}
U0 QuessCenter(CD3I32 *middle,CD3I32 *l,CD3I32 *r,
	F64 desired_x,F64 desired_y,F64 l_min_deriv=0.,
	F64 r_min_deriv=0.) {
  F64 at,closest_at,closest;
  Bool tried_up=FALSE,tried_down=FALSE;
  I64 sign=1,quessed_x,quessed_y;
  F64 deriv,step;
//Quess y vertex cordnate
  closest_at=l->y;step=l->y;
  closest=F64_MAX;
  while(!tried_up||!tried_down) {
    middle->y=step;
    CalcBezier(middle,l,middle,r);
    at=l->y*0.5`2+middle->y*2*.5*.5+r->y*.5`2;
//left deritive
    if(2.*Abs(at-l->y)>=l_min_deriv)
      if(2.*Abs(r->y-at)>=r_min_deriv) {
        if(Abs(at-desired_y)<closest) {
	  closest_at=step;
	  closest=Abs(at-desired_y);
        }
        if(at>desired_y) {
	  sign=-1;
	  tried_up=TRUE;
        } else if(at<desired_y) {
	  sign=1;
	  tried_down=TRUE;
        } else
	  break;
      }
    step+=sign;
  }
  quessed_y=closest_at;
//Guess x cordnate
  tried_down=FALSE,tried_up=FALSE;
  closest_at=l->x;
  step=l->x;
  closest=F64_MAX;
  while(!tried_up||!tried_down) {
    middle->x=step;
    CalcBezier(middle,l,middle,r);
    at=l->x*0.5`2+middle->x*2*.5*.5+r->x*.5`2;
    if(Abs(at-desired_x)<closest) {
      closest_at=step;
      closest=Abs(at-desired_y);
    }
    if(at>desired_x) {
      sign=-1;
      tried_up=TRUE;
    } else if(at<desired_x) {
      sign=1;
      tried_down=TRUE;
    } else
      break;
    step+=sign;
  }
  quessed_x=closest_at;
  middle->x=quessed_x,middle->y=quessed_y;
}
class CDisplayNode {
  AST *ast;
  CD2 hover_node_pos;
  F64 handle_left_x,handle_left_y;
  F64 handle_right_x,handle_right_y;
  F64 handle_x,handle_y;
  F64 bound_l,bound_r;
  F64 max_y;
  F64 l_deriv,r_deriv;
  I32 color,thick;
  I64 level;
  I64Set *connects;
};
U0 DisplayNodeDel(CDisplayNode *n) {
  I64 i;
  if(n->connects) {
    i=n->connects->cnt;
    while(--i>=0)
     DisplayNodeDel(n->connects->body[i]);
  }
}
CTrie *DisplayNodeGetHoverWord(CDisplayNode *n,I64 ms_x,I64 ms_y) {
  I64 i;
 AST *ret;
  if(n->ast&&Sqrt(Sqr(ms_x-n->hover_node_pos.x)+Sqr(ms_y-n->hover_node_pos.y))<16) {
    if(n->ast->word)
      return n->ast->word;
  }
  if(n->connects) {
    i=n->connects->cnt;
    while(--i>=0)
     if(ret=DisplayNodeGetHoverWord(n->connects->body[i],ms_x,ms_y)) {
       return ret;
     }
  }
  return NULL;
}

#define WORD_MARGIN 20
#define CURVE_MARGIN 40
class CDisplayTmp {
  I64 *word_offsets;
  U8 **words;
  I64 word_cnt;
  F64 word_font_size;
  F64 definition_font_size;
  F64 xoff,yoff,max_y;
};
F64 Center(F64 a,F64 b) {
  return Min(a,b)+(Max(a,b)-Min(a,b))/2;
}
//Returns maximum 4 drawn
F64 DrawConnect(CDC*dc,I64 level=0,F64 x,F64 y,F64 x2,F64 y2,F64 mdl,F64 mdr,F64 *vx=NULL,F64 *vy=NULL,F64 *dl=NULL,F64 *dr=NULL,F64 *zenith_x) {
  F64 highest;
  CD3I32 ctrls[3];
  ctrls[0].x=x;
  ctrls[0].y=y;
  ctrls[2].x=x2;
  ctrls[2].y=y2;
  QuessCenter(&ctrls[1],&ctrls[0],&ctrls[2],Center(x2,x),Max(y2,y)+CURVE_MARGIN*level,mdl,mdr);
  dc->thick=3;
  highest=GrPreciseBezier(dc,ctrls,zenith_x);
  if(vx) *vx=ctrls[0].x*.5`2+ctrls[1].x*2*.5*(1-.5)+ctrls[2].x*.5`2;
  if(vy) *vy=ctrls[0].y*.5`2+ctrls[1].y*2*.5*(1-.5)+ctrls[2].y*.5`2;
  if(dl) *dl=2.*(ctrls[1].y-ctrls[0].y);
  if(dr) *dr=2.*(ctrls[2].y-ctrls[1].y);
  return highest;
}
I64 SideSort(AST *a,AST *b) {
  return a->word_idx-b->word_idx;
}
I64 SideSortRev(AST *a,AST *b) {
  return b->word_idx-a->word_idx;
}
//Fs->user_data has the distance we are measuring from
I64 DistSort(AST *a,AST *b) {
  return AbsI64(a->word_idx-Fs->user_data)-AbsI64(b->word_idx-Fs->user_data);
}
#include "TrueType";
I64 SexyGrPrintSize(CDC *dc,I64 size,I64 x,I64 y,I64 cursor_pos,U8 *fmt,...) {
  Bool del=FALSE;
  if(dc==NULL)
   del=TRUE,dc=DCNew(1,1);
  fmt=StrPrintJoin(NULL,fmt,argc,argv);
  I64 w=TTF_RenderText(dc,x,y,fmt,size,,cursor_pos);
  Free(fmt);
  if(del) DCDel(dc);
  return w;
}
I64 StrLenUTF8(U8 *s) {
  I64 l=0;
  while(ReadUTF8(s,&s))
    ++l;
  return l;
}
I64 SliceUTF8(U8 *to,U8 *str,I64 len) {
  I64 ptr=0;
  U8 *old;
  while(--len>=0) {
    old=str;
    ReadUTF8(str,&str);
    if(to) {
      MemCpy(to,old,str-old);
      to+=str-old;
    }
    ptr+=str-old;
  }
  *to=0;
  return ptr;
}
I64 DrawSexyWord(CDC *dc,F64 fsize,I64 x,I64 y,CTrie *word,U8 *text,I64 cursor_pos=-1) {
  CDC *odc=dc;
  if(!dc) dc=DCNew(1,1);
  I64 ox=x;
  I64 inflect_color=dc->color^7;
  I64 old_color=dc->color;
  if(!word) return x;
  U8 *tmp;
  U8 buf[STR_LEN];
  I64 badv=0,fadv=0;
  I64 padv=0,sadv=0;
  I64 ptr=0;
  if(tmp=word->prefix)
    padv=StrLen(tmp);
  if(tmp=word->back_declension)
    badv=StrLen(tmp);
  if(tmp=word->front_declension)
    fadv=StrLen(tmp);
  if(tmp=word->suffix)
    sadv=StrLen(tmp);
  if(padv) {
    dc->color=DKGRAY;
    ptr=SliceUTF8(buf,text,padv);
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",buf);
    text+=ptr;
    cursor_pos-=ptr;
  }
  if(badv) {
    dc->color=inflect_color;
    ptr=SliceUTF8(buf,text,badv);
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",buf);
    text+=ptr;
    cursor_pos-=ptr;
  }
  if(fadv) {
    dc->color=old_color;
    ptr=StrLenUTF8(text)-fadv-sadv;
    ptr=SliceUTF8(buf,text,ptr);
    text+=ptr;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",buf);
    cursor_pos-=ptr;
    dc->color=inflect_color;
    ptr=SliceUTF8(buf,text,fadv);
    text+=ptr;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",buf);
    cursor_pos-=ptr;
    dc->color=DKGRAY;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",text);
  } elseif(!sadv){
    dc->color=old_color;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",text);
  } else {
    ptr=StrLenUTF8(text)-sadv;
    ptr=SliceUTF8(buf,text,ptr);
    text+=ptr;
    dc->color=old_color;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",buf);
    cursor_pos-=ptr;
    dc->color=DKGRAY;
    x+=SexyGrPrintSize(dc,fsize,x,y,cursor_pos,"%s",text);
  }
  dc->color=old_color;
  if(!odc) DCDel(dc);
  return x-ox;
}


I64 DrawWordInfo(CDC *dc,I64 x,I64 y,CTrie *word,Bool dummy=FALSE,U8 *text) {
  I64 ox=x;
  F64 sub=14.;
  if(dummy) dc=DCNew(1,1);
  if(word->flags&(NOUN|PRONOUN|ADJECTIVE|PARTICIPLE)) {
    dc->color=GREEN;
    if(word->flags&MASCULINE) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"M");
    } else if(word->flags&FEMININE) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"F");
    } else if(word->flags&NEUTER) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"N");
    }

    dc->color=PURPLE;
    if(word->flags&COMPARATIVE) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Comp");
    } else if(word->flags&COMPARATIVE) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Sup");
    }
    if(word->flags&NOMITIVE) {
      dc->color=LTGREEN;
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"N");
    } else if(word->flags&ACCUSATIVE) {
      dc->color=LTRED;
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"A");
    } else if(word->flags&GENITIVE) {
      dc->color=LTCYAN;
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"G");
    } else if(word->flags&ABLATIVE) {
      dc->color=LTBLUE;
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Ab");
    } else if(word->flags&VOCATIVE) {
      dc->color=LTPURPLE;
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Vo");
    }

_p_cnt:
    dc->color=RED;
    if(word->flags&_3P) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"3");
    } else if(word->flags&_2P) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"2");
    } else if(word->flags&_1P) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"1");
    }

    dc->color=BLACK;
    if(word->flags&PLURAL) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"P");
    } else {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"S");
    }
  } else if(word->flags&VERB) {
    dc->color=BLUE;
    if(word->flags&IMPERFECT) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Imp");
    } else if(word->flags&FUTURE) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Fut");
    } else if(word->flags&PERFECT) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Per");
    } else if(word->flags&PLUPERFECT) {
      x+=SexyGrPrintSize(dc,sub,x,y,-1,"Plu");
    }
    goto _p_cnt;
  }
  if(dummy) DCDel(dc);
  return x-ox;
}
//Only group nouns with nouns and verbs with verbs
Bool IsOfSomeType(AST *a,AST *b) {
  if(a->flags&VERB^^b->flags&VERB)
    return FALSE;
  if(a->flags&(NOUN|ADJECTIVE)^^b->flags&(NOUN|ADJECTIVE))
    return FALSE;
  return TRUE;
}
//Used for grouping togheter conjunctions
AST *GetFirstConjPair(AST *ast) {
  I64 min=I64_MAX,idx;
  AST*best=ast,*tmp;
  if(!(ast->flags&(CONJUNCTION|CONJUNCTION2)))
     return ast;
  if(!ast->args) return ast;
  if(ast->base_expression) {
    min=ast->base_expression->start;
    best=ast->base_expression;
  }
  for(idx=0;idx!=ast->args->cnt;idx++) {
    tmp=ast->args->body[idx];
    if(tmp->start<min&&tmp!=ast)  {
      min=tmp->start;
      best=tmp;
    }
  }
  if(ast!=best)
    return GetFirstConjPair(best);
  return best;
}
//Used for grouping togheter conjunctions
AST *GetLastConjPair(AST *ast) {
  I64 max=I64_MIN,idx;
  AST*best=ast,*tmp;
  if(!(ast->flags&(CONJUNCTION|CONJUNCTION2)))
     return ast;
//Self is an argument
  if(!ast->args) return ast;
  if(ast->base_expression) {
    max=ast->base_expression->start;
    best=ast->base_expression;
  }
  for(idx=0;idx!=ast->args->cnt;idx++) {
    tmp=ast->args->body[idx];
    if(tmp->start>max)  {
      max=tmp->start;
      best=tmp;
    }
  }
  if(ast!=best)
    return GetLastConjPair(best);
  return best;
}

CDisplayNode *DisplayNode(CDisplayTmp *world,CDC *dc,AST *ast,I64 level=0,I64 *max_h=NULL) {
  CDisplayNode *ret=GCCAlloc(sizeof CDisplayNode),*tmp;
  ret->ast=ast;
  ret->level=level;
  ASTSet *set;
  F64 x,y,ww=0,x2,y2,handle_x,handle_y;
  I64 color=LTGRAY,idx,run,run2,idx2,old_color,old_color2;
  I64Set *left_sides=NULL,*right_sides=NULL,*set2=NULL;
  U8 *optr,*base_word;
  I64 level2,max_level=0;
  AST *ast2;
  F64 use_handle_x,use_handle_y;
  F64 use_x,use_y;
  CD3I32 ctrls[3];
  I64 bound_l,bound_r;
  Bool is_left_side;
  F64 max_l_deriv=0.,max_r_deriv=0.;
  switch(ast->act_as_type) {
      break;case AST_NOUN: color=GREEN;
      break;case AST_CONJUNCTION: color=RED;
      break;case AST_VERB: color=BLUE;
      break;case AST_OF: color=BROWN;
      break;case AST_WHERE: color=PURPLE;
      break;case AST_ADJECTIVE: color=CYAN;
      break;case AST_INFINITIVE: color=LTPURPLE;
      break;case AST_MEASURE: color=LTGREEN;
      break;case AST_ADVERB: color=LTCYAN;
      break;case AST_QUESTION: color=LTGRAY;
  }
  old_color2=dc->color;
  ret->color=color;
  if(ast->word) {
    y=8;
    x=world->word_offsets[ast->word_idx];
    dc->color=color;
    x2=DrawSexyWord(NULL,17,x+1,y,ast->word,world->words[ast->word_idx]);
    x2=x-x2/2;
    DrawSexyWord(dc,17.,x2,y,ast->word,world->words[ast->word_idx]);

    x2=DrawWordInfo(NULL,x,y+20,ast->word,TRUE,world->words[ast->word_idx]);
    x2=x-x2/2;
    DrawWordInfo(dc,x2,y+20,ast->word,,world->words[ast->word_idx]);
    if(optr=ast->word->translation) {
      x2=x-SexyGrPrintSize(NULL,14.,x,y+2*20,"%s",optr)/2;
      dc->color=BLACK;
      SexyGrPrintSize(dc,14.,x2,2*20,"%s",optr);
    }
    ret->hover_node_pos.x=x;
    ret->hover_node_pos.y=y+3+20*3+2.5;
    GrFillCircle(dc,x,y+3+3*20+2.5,0,5);
    x2=x;
    y2=y+3*20;
    ret->handle_x=x2;
    ret->handle_y=y2;
    ret->bound_l=x2;
    ret->bound_r=x2;
    ret->max_y=y2;
  } else if(ast->base_expression) {
    tmp=DisplayNode(world,dc,ast->base_expression,,&y);
    x2=tmp->handle_x;
    y2=tmp->handle_y;
    ret->handle_x=x2;
    ret->handle_y=y2;
    ret->bound_l=x2;
    ret->bound_r=x2;
    ret->hover_node_pos.x=I64_MAX;
    ret->hover_node_pos.y=I64_MAX;
    ret->max_y=y2;
  } else
    Break;
  ret->handle_left_x=ret->handle_x;
  ret->handle_left_y=ret->handle_y;
  ret->handle_right_x=ret->handle_x;
  ret->handle_right_y=ret->handle_y;
//I will sort the left and right sides by distance
  for(run=0;run<=10;run++) {
    if((set=ast->nomitive)&&run==0) {
ent:
      for(idx=0;idx!=set->cnt;idx++) {
        set2=I64SetAdd(set2,set->body[idx]);
        if(set->body[idx](AST*)->word_idx<ast->word_idx)
	  left_sides=I64SetAdd(left_sides,set->body[idx]);
        else
	  right_sides=I64SetAdd(right_sides,set->body[idx]);
      }
    } else if((set=ast->accusative)&&run==1) {
      goto ent;
    } else if((set=ast->dative)&&run==2) {
      goto ent;
    } else if((set=ast->genitive)&&run==3) {
      goto ent;
    } else if((set=ast->adjective)&&run==4) {
      goto ent;
    } else if((set=ast->preposition)&&run==5) {
      goto ent;
    } else if((set=ast->conjunction)&&run==6) {
      goto ent;
    } else if((set=ast->measurement)&&run==7) {
      goto ent;
    } else if((set=ast->adverb)&&run==8) {
      goto ent;
    } else if((set=ast->ablative)&&run==9) {
      goto ent;
    }else if((set=ast->question)&&run==10) {
      goto ent;
    }
  }
//Sort the left and right sides
  if(left_sides)
    QSortI64(left_sides->body,left_sides->cnt,&SideSortRev);
  if(right_sides)
    QSortI64(right_sides->body,right_sides->cnt,&SideSort);
  if(set2) {
    Fs->user_data=ast->word_idx;
    QSortI64(set2->body,set2->cnt,&DistSort);
  }
  set=set2;
  if(set)
    for(idx=0;idx!=set->cnt;idx++) {
      if(I64SetHasItem(ast->nomitive,set->body[idx]))
        dc->color=LTGREEN;
      else if(I64SetHasItem(ast->accusative,set->body[idx]))
        dc->color=LTRED;
      else if(I64SetHasItem(ast->dative,set->body[idx]))
        dc->color=LTCYAN;
      else if(I64SetHasItem(ast->genitive,set->body[idx]))
        dc->color=BROWN;
      else if(I64SetHasItem(ast->adjective,set->body[idx]))
        dc->color=BLUE;
      else if(I64SetHasItem(ast->preposition,set->body[idx]))
        dc->color=LTGRAY;
      else if(I64SetHasItem(ast->conjunction,set->body[idx]))
        dc->color=RED;
      else if(I64SetHasItem(ast->measurement,set->body[idx]))
        dc->color=PURPLE;
      else if(I64SetHasItem(ast->adverb,set->body[idx]))
        dc->color=CYAN;
      else if(I64SetHasItem(ast->ablative,set->body[idx]))
        dc->color=BLACK;
      else if(I64SetHasItem(ast->question,set->body[idx]))
        dc->color=DKGRAY;
      if(I64SetHasItem(left_sides,set->body[idx])) {
        is_left_side=TRUE;
        level2=0;
        for(idx2=0;idx2!=left_sides->cnt;idx2++) {
	  ast2=left_sides->body[idx2];
//	  if(ast2->disp_node)
//	    level2=MaxI64(ast2->disp_node->level,level2);
	  if(ast2==set->body[idx])
	    break;
        }
      }
      if(I64SetHasItem(right_sides,set->body[idx])) {
        is_left_side=FALSE;
        level2=0;
        for(idx2=0;idx2!=right_sides->cnt;idx2++) {
	  ast2=right_sides->body[idx2];
//	  if(ast2->disp_node)
//	    level2=MaxI64(ast2->disp_node->level,level2);
	  if(ast2==set->body[idx])
	    break;
        }
      }
      max_level=MaxI64(max_level,level2);
      tmp=DisplayNode(world,dc,set->body[idx],level2+1);
      set->body[idx](AST*)->disp_node=tmp;
      ret->connects=I64SetAdd(ret->connects,tmp);
      use_x=x2;
      use_y=y2;

      if(!ast->base_expression) {
        goto use_middle;
      } 
      if(ast->flags&(CONJUNCTION|CONJUNCTION2)&&!(ast->flags&CONJUNCTION_NO_JOIN)) {
conj:
        bound_l=ast->base_expression->start;
        bound_r=ast->base_expression->end;
        ast2=set->body[idx];
//Ignore "[","]"
        if(ast2->end==bound_l&&IsOfSomeType(ast,ast2)) {
	  ast2=GetLastConjPair(ast2);
	  while(0<=bound_l<world->word_cnt) {
	    if(StrCmp(world->words[bound_l],"["))
	      break;
	    bound_l++;
	  }
	  use_handle_x=tmp->bound_r;
	  use_handle_y=tmp->handle_right_y;
	  use_x=world->word_offsets[bound_l];
	  use_y=use_handle_y;
        } else if(set->body[idx]->start==bound_r&&IsOfSomeType(ast,ast2)) {
	  ast2=GetFirstConjPair(ast2);
	  use_handle_x=tmp->bound_l;
	  use_handle_y=tmp->handle_left_y;
//Dumb hack,make
	  bound_r--;
	  while(0<=bound_r<world->word_cnt) {
	    if(StrCmp(world->words[bound_r],"]"))
	      break;
	    bound_r--;
	  }
	  use_x=world->word_offsets[bound_r];
	  use_y=use_handle_y;
        } else 
	  goto use_middle;
      } else {
use_middle:;
        use_handle_x=tmp->handle_x;
        use_handle_y=tmp->handle_y;
      }
have_handle:
//ret->handle_y set here
      if(is_left_side) {
        world->max_y=Max(world->max_y,ret->handle_y=DrawConnect(dc,level2+1,use_handle_x,use_handle_y,use_x,use_y,0,max_l_deriv,&handle_x,&handle_y,&ret->l_deriv,&ret->r_deriv,&ret->handle_x));
        max_l_deriv=Max(Abs(ret->r_deriv*.55),max_l_deriv); //our target node is on the left side,our current node is on the rgiht side
      } else {
        world->max_y=Max(world->max_y,ret->handle_y=DrawConnect(dc,level2+1,use_handle_x,use_handle_y,use_x,use_y,max_r_deriv,0,&handle_x,&handle_y,&ret->l_deriv,&ret->r_deriv,&ret->handle_x));
        max_r_deriv=Max(Abs(ret->l_deriv*.55),max_r_deriv);  //our target node is on the right side,our current node is on the left side
      }
      ret->max_y=Max(Max(ret->max_y,handle_y),tmp->max_y);
      ret->bound_l=Min(ret->bound_l,tmp->bound_l);
      ret->bound_r=Max(ret->bound_r,tmp->bound_r);
      old_color=dc->color;
//      dc->color=BLACK;
//            GrFillCircle(dc,tmp->handle_x,tmp->handle_y,0,10);
      dc->color=old_color;
    }
//If we have connects of each side,make our connect in the "center"
  if(1) {
    ret->bound_l=world->word_offsets[ast->start];
    ret->bound_r=world->word_offsets[ast->end-1];
    ret->handle_x=(ret->bound_r-ret->bound_l)/2.+ret->bound_l;
    ret->handle_y=ret->max_y+8;
  }

  if(ast->number) {
    dc->color=BLACK;
    optr=MStrPrint("%d",ast->number);
    GrTextBox3(dc,ret->handle_x-StrLen(optr)*4,ret->handle_y+4,0,optr);
    ret->handle_y+=16;
    Free(optr);
  }



  if(!ret->connects) {
    ret->handle_left_x=ret->handle_x;
    ret->handle_left_y=ret->handle_y;
    ret->handle_right_x=ret->handle_x;
    ret->handle_right_y=ret->handle_y;
  } else {
    tmp=ret->connects->body[0];
    ret->handle_left_x=tmp->handle_left_x;
    ret->handle_left_y=tmp->handle_left_y;
    tmp=ret->connects->body[ret->connects->cnt-1];
    ret->handle_right_x=tmp->handle_right_x;
    ret->handle_right_y=tmp->handle_right_y;
  }
  dc->color=old_color2;
  ret->level=level;
  return ret;
}

U0 CopyRegion(CDC *dst,CDC *img,I64 dx,I64 dy,I64 x,I64 y,I64 w,I64 h) {
  I64 x2,y2;
  for(x2=x;x2!=x+w;x2++) {
    for(y2=y;y2!=y+h;y2++) {
      dst->color=GrPeek(img,x2,y2);
      if(dst->color==-1) dst->color=TRANSPARENT;
      GrPlot(dst,dx+x2-x,dy+y2-y);
    }
  }
}
//Like "word-wrap" for images
CDC *SplitImageIntoColumn(CDC *img,I64 width=GR_WIDTH) {
  I64 clip_cnt=img->width/width;
  if(img->width%width)
    clip_cnt++;
  CDC *ret=DCNew(width,img->height*clip_cnt);
  while(--clip_cnt>=0) {
    CopyRegion(ret,img,0,clip_cnt*img->height,clip_cnt*width,0,width,img->height);
  }
  return ret;
}

CDC *DrawSentence(AST*sentence,I64 word_cnt,U8 **words,I64 dwidth=I64_MAX,I64 *w=NULL,I64 *h=NULL,I64 ms_x=0,I64 ms_y=0,CTrie **hover_over=NULL) { 
  I64 off,idx,inf_d,wc,cw;
  CDC *dc,*wrapped;
  F64 ww=0;
  I64 last_wrap=0,diff;
  U8 *closest;
  CDisplayTmp t;
  CTrie **forms;
  AST *untainted=ASTClone(sentence);
  wc=ASTGetTrieWords(sentence,NULL);
  forms=GCCAlloc(word_cnt*8);
  t.words=words;
  t.word_font_size=17;
  t.word_cnt=word_cnt;
  t.definition_font_size=14;
  ASTGetTrieWords(sentence,forms);
  t.xoff=0,t.yoff=0;
  t.word_offsets=GCCAlloc(word_cnt*8);
  t.max_y=0.;
  for(off=40,idx=0;idx!=word_cnt;idx++) {
    cw=0;
    if(forms[idx]) {
      cw=StrLen(forms[idx]->str);
      if(forms[idx]->translation) 
        cw=MaxI64(StrLen(forms[idx]->translation),cw);
    }
    t.word_offsets[idx]=off+cw*4;
    if(!StrCmp(words[idx],"[")||!StrCmp(words[idx],"]"))
      ;
    else
      off+=40+cw*8;
//Make "image-wrap" points
    if(idx) {
      if(t.word_offsets[idx]-last_wrap+WORD_MARGIN>=dwidth) {
        diff=t.word_offsets[idx]-t.word_offsets[idx-1];
        t.word_offsets[idx-1]=(last_wrap=CeilI64(t.word_offsets[idx-1],dwidth))+WORD_MARGIN;
        off=t.word_offsets[idx]=diff+t.word_offsets[idx-1];
        off+=FONT_WIDTH*cw;
        off+=WORD_MARGIN;
      }
    }
  }
  I64 width=off;
//Pass 2,Make "[" and "]" point to leading,trailing words
  for(idx=word_cnt-1;idx>=0;idx--) {
    if(!StrCmp(words[idx],"["))
	t.word_offsets[idx]=off;
     else
	off=t.word_offsets[idx];
  }
  for(off=40,idx=0;idx!=word_cnt;idx++) {
    if(!StrCmp(words[idx],"]"))
	t.word_offsets[idx]=off;
     else
	off=t.word_offsets[idx];
 
  }
  dc=DCNew(1,1);
  DisplayNodeDel(DisplayNode(&t,dc,sentence));
  DCDel(dc);
  dc=DCNew(width+WORD_MARGIN,t.max_y+8+10+FONT_HEIGHT*4); //See DisplayNode
  DCFill(dc,TRANSPARENT);
//DisplayNode will set ->disp_node of the ast,so use the one without the ->	disp_node's
  CDisplayNode*dn=DisplayNode(&t,dc,untainted);
  if(hover_over) *hover_over=NULL;
  for(idx=0;idx!=word_cnt;idx++) {
    if(SqrI64(t.word_offsets[idx]-ms_x)+SqrI64(32-ms_y)<32*32) {
      if(hover_over) {
        *hover_over=forms[idx];
      }
    }

  }
  DisplayNodeDel(dn);
  if(dwidth!=I64_MAX&&width+8>dwidth) {
    wrapped=SplitImageIntoColumn(dc,dwidth);
    DCDel(dc);
  } else
    wrapped=dc;
  if(w) *w=dc->width;
  if(h) *h=dc->height;
  ASTDel(untainted);
  return wrapped;
}
WinMax;
U0 DumpSentence(...) {
  try {
  I64 *dummy_stk=GCCAlloc(8*(1+argc));
  I64 w,h;
  CDC *dc;
  dummy_stk[0]=argc;
  MemCpy(dummy_stk+1,argv,argc*8);
  AST *sent=ParseSentenceJoin(argc+1,dummy_stk);
  if(sent) {
    dc=DrawSentence(sent,argc,argv);
"












";
    DocSprite(DocPut,DC2Sprite(dc));
"












";
    CFileBMP *bmp=BMPRLE4To(dc);
    DCColorChg(dc,TRANSPARENT,WHITE);
    FileWrite("sent.BMP",bmp,bmp->file_size);
    Free(bmp);
    DCDel(dc);
    ASTDel(sent);
  }
  } catch PutExcept(FALSE);
}
public Bool WordTextBox(CDC *dc=0,I64 x1,I64 y1,U8 *s,I64 bg_color=YELLOW)
{//3D. Transformation. DCF_SYMMETRY is silly.
  U8 *ptr;
  if(!dc) dc=gr.dc;
  I64 ch,res,w,w_max,h;
  I64 old=dc->color;
  I64 border=2;
  if (!s) return FALSE;
  ptr=s;
  w=0;	w_max=0; h=FONT_HEIGHT;

  while (ch=*ptr++) {
    if (ch=='\t')
      w=CeilU64(w+FONT_WIDTH,FONT_WIDTH*8);
    else if (ch=='\n') {
      if (w>w_max) w_max=w;
      w=0;
      h+=FONT_HEIGHT;
    } else
      w+=FONT_WIDTH;
  }
  if (w>w_max) w_max=w;
  dc->color=bg_color;
  GrRect(dc,x1-border,y1-border,w_max+border<<1,h+border<<1);
  dc->color=old;
  res=GrPrint(dc,x1,y1,"%s",s);
  res|=GrLine(dc,x1-border	   ,y1-border  ,x1+w_max+border,y1-border);
  res|=GrLine(dc,x1-border	   ,y1+h+border,x1+w_max+border,y1+h+border);
  res|=GrLine(dc,x1-border	   ,y1-border  ,x1-border,y1+h+border);
  res|=GrLine(dc,x1+w_max+border,y1-border  ,x1+w_max+border,y1+h+border);

  return !!(res);
}


U0 InteractViewDrawIt(CTask *t,CDC *dc) {
  U8 *st;
  U8 *tran;
  U8 **toks;
  I64 tcnt;
  AST *ast;
  CTrie *word=NULL;
  CDC *dc2;
  CDoc *d=DocNew;
  I64 x,y;
  if(ast=FramePtr("InteractAst",t)) {
    if(st=FramePtr("InteractText",t)) {
    toks=TokenizeSentence(st,&st,TRUE,TRUE);
    tcnt=0;
    while(toks[tcnt])
      tcnt++;
    ast=ASTClone(ast);
    dc2=DrawSentence(ast,tcnt,toks,,,,x=ms.pos.x-t->pix_left-t->scroll_x,y=ms.pos.y-t->pix_top-t->scroll_y,&word);
    FramePtrSet("InteractCurWord",word,t);
    GrBlot(dc,0,0,dc2);
    dc->color=RED;
    if(word&&word->str) {
      DocPrint(d,"Word %s:\n",word->str);
      tran=GetTranslations(word->str,TRUE);
      if(tran) {
	DocPrint(d,"Defs:\n%s\n",tran);
	Free(tran);
      }

//No declensions (like numbers that dont decline)
/*#define INDECLINABLE (1<<32)
#define PRESENT (1<<33)
#define PASSIVE (1<<34)
#define IMPERATIVE (1<<35)
#define PARTICIPLE (1<<36)
#define GERUND (1<<37)
#define COMPARATIVE (1<<38)
#define SUPERLATIVE (1<<39)
#define PARTICLE (1<<40)
#define CONJUNCTION2 (1<<41) //dixeque Words ending in -que
#define IS (1<<42) //Words like sum
#define DETIRMINER (1<<43) //things *that* are green */
      if(word->flags&NOMITIVE)
	DocPrint(d,"Nom.\n");
      if(word->flags&GENITIVE)
	DocPrint(d,"Gen.\n");
      if(word->flags&DATIVE)
	DocPrint(d,"Dat.\n");
      if(word->flags&ACCUSATIVE)
	DocPrint(d,"Acc.\n");
      if(word->flags&ABLATIVE)
	DocPrint(d,"Abl.\n");
      if(word->flags&SINGULAR)
	DocPrint(d,"Sing.\n");
      if(word->flags&PLURAL)
	DocPrint(d,"Plrl.\n");
      if(word->flags&FEMININE)
	DocPrint(d,"Fem.\n");
      if(word->flags&MASCULINE)
	DocPrint(d,"Masc.\n");
      if(word->flags&INFINITIVE)
	DocPrint(d,"Inf.\n");
      if(word->flags&_1P)
	DocPrint(d,"1st.\n");
      if(word->flags&_2P)
	DocPrint(d,"2nd.\n");
      if(word->flags&_3P)
	DocPrint(d,"3rd.\n");
      if(word->flags&IMPERFECT)
	DocPrint(d,"Imperfect.\n");
      if(word->flags&FUTURE)
	DocPrint(d,"Fut.\n");
      if(word->flags&CONJUNCTION)
	DocPrint(d,"Conj.\n");
      if(word->flags&VERB)
	DocPrint(d,"V.\n");
      if(word->flags&NOUN)
	DocPrint(d,"N.\n");
      if(word->flags&ADVERB)
	DocPrint(d,"Adv.\n");
      if(word->flags&ADJECTIVE)
	DocPrint(d,"Adj.\n");
      if(word->flags&PRONOUN)
	DocPrint(d,"Pron.\n");
      if(word->flags&REFLEXIVE)
	DocPrint(d,"Reflex.\n");
      if(word->flags&POSSESIVE)
	DocPrint(d,"Poss.\n");
      if(word->flags&DEMONSTRATIVE)
	DocPrint(d,"Demon.\n");
      if(word->flags&INTEROGITIVE)
	DocPrint(d,"Inter.\n");
      if(word->flags&NEUTER)
	DocPrint(d,"Neut.\n");
      if(word->flags&RELATIVE)
	DocPrint(d,"Rel.\n");
      if(word->flags&PREPOSITION)
	DocPrint(d,"Prep.\n");
      if(word->flags&PERFECT)
	DocPrint(d,"Per.\n");
      if(word->flags&PLUPERFECT)
	DocPrint(d,"Plu.\n");
      if(word->flags&SUBJUNCTIVE)
	DocPrint(d,"Sub.\n");
	
      tran=DocSave(d);
      WordTextBox(dc,x,y,StrUtil(tran,SUF_REM_CTRL_CHARS));
      Free(tran);
    }
//    DisplayNodeDel(ast->disp_node);
    ASTDel(ast);
    DCDel(dc2);
    tcnt=0;
    while(toks[tcnt])
      Free(toks[tcnt++]);
    Free(toks);
    }
  }
  DocDel(d);
}
U0 InteractView(U8 *st) {
  U8 **toks;
  I64 tcnt;
  CTrie *word;
  AST *ast;
  U8 *trans;
  CDoc *doc;
  SettingsPush;
  DocClear;
  FramePtrAdd("InteractCurWord",NULL);
  FramePtrAdd("InteractText",st);
  toks=TokenizeSentence(st,&st,TRUE,TRUE);
  tcnt=0;
  while(toks[tcnt])
    tcnt++;
  ast=ParseSentenceJoin(tcnt,toks);
  if(!ast) goto fin;
  Fs->draw_it=&InteractViewDrawIt;
"


  ";
//DumpAST(ast);
  FramePtrAdd("InteractAst",ast);
  I64 msg,a,b;
  Bts(&Fs->win_inhibit,WIf_SELF_GRAB_SCROLL);
  Bts(&Fs->win_inhibit,WIf_FOCUS_TASK_GRAB_SCROLL);
  I64 sx=0,sy=0,ox=ms.pos.x,oy=ms.pos.y;
  while(ast) {
    msg=ScanMsg(&a,&b);
    if(ms.lb&&Bt(kbd.down_bitmap,SC_CTRL)) {
      sx+=(ms.pos.x-ox)*4;
      sy+=(ms.pos.y-oy)*4;
    }
    if(msg==MSG_MS_L_DOWN) {
      if(word=FramePtr("InteractCurWord")) {
        doc=DocNew;
        DocPrint(doc,"$$PURPLE$$$$TX+CX,\"Pick a default translation\"$$\n\n");
        for(tcnt=0;trans=GetTranslation(word->str,TRUE,FALSE,tcnt);tcnt++) {
	  DocPrint(doc,"$$MU,\"%d:%Q\",LE=%d$$\n",tcnt,trans,tcnt);
        }
        I64 want=PopUpMenu(doc);
        if(0<=want<tcnt) {
	  SetWordDftTranslationIdx(word->str,want);
        }
        DocDel(doc);
      }
    } else if(msg==MSG_KEY_DOWN) {
      if(a==CH_ESC)
        break;
    }

    Fs->scroll_x=sx;
    Fs->scroll_y=sy;
    ox=ms.pos.x;
    oy=ms.pos.y;
    Refresh;
  }
  Btr(&Fs->win_inhibit,WIf_FOCUS_TASK_GRAB_SCROLL);

  fin:
  tcnt=0;
  while(toks[tcnt])
    Free(toks[tcnt++]);
  Free(toks);
  FramePtrDel("InteractCurWord");
  FramePtrDel("InteractText");
  FramePtrDel("InteractAst");
  ASTDel(ast);
  SettingsPop;
}
U0 DumpSentences(U8 *st,U8 *translations=NULL,CDoc *to_file=NULL) {
  U8 **toks;
  I64 tcnt;
  I64 w=0,h=0;
  AST *ast;
  CDC *dc,*tmp_dc;
  CDC *sents[0x800];
  I64 sent_cnt=0;
  U8 *tmp;
  CFileBMP *bmp;
  while(*SkipWhitespace(st)) {
    tcnt=0;
    toks=TokenizeSentence(st,&st,TRUE,TRUE);
    while(tmp=toks[tcnt]) {
      tcnt++;
    }
    ast=ParseSentenceJoin(tcnt,toks);
"((%x))\n",ast;
    if(ast) {
	DumpAST(ast);
	NumberAST(ast);
      dc=DrawSentence(ast,tcnt,toks);
"












      ";
      DocSprite(DocPut,DC2Sprite(dc));
"












      ";
      sents[sent_cnt++]=dc;
      w=MaxI64(dc->width,w);
      h+=dc->height;;
    }
    tcnt=0;
    while(toks[tcnt])
      Free(toks[tcnt++]);
    Free(toks);
  }
  if(translations) {
    tcnt=0;
    while(tmp=LstSub(tcnt,translations)) {
      if(8*StrLen(tmp)>w)
        w=8*StrLen(tmp);
      tcnt++;
    }
    h+=tcnt*25;
  }
  dc=DCNew(w,h);
  DCFill(dc,WHITE);
  h=0;
  for(tcnt=0;tcnt<sent_cnt;tcnt++) {
    tmp_dc=sents[tcnt];
    w=dc->width/2.-tmp_dc->width/2.;
    GrBlot(dc,w,h,tmp_dc);
    h+=tmp_dc->height;
    if(translations) {
      if(tmp=LstSub(tcnt,translations)) {
        w=dc->width/2.-8*StrLen(tmp)/2.;
        dc->color=BLACK;
        GrPrint(dc,w,h+(25-8)/2.,"%s",tmp);
        h+=25;
      }
    }
    DCDel(tmp_dc);
  }
  if(to_file) {
    tmp_dc=DocRead(to_file);
    DocSprite(tmp_dc,DC2Sprite(dc));
    for(h=0;h<dc->height;h+=8) {
      DocPrint(tmp_dc,"\n");
    }
    DocPrint(tmp_dc,"\n\n");
    DocWrite(tmp_dc);
    DocDel(tmp_dc);
  }

  bmp=BMPRLE4To(dc); 
  FileWrite("sent.BMP",bmp,bmp->file_size);
  Free(bmp);
  DCDel(dc);
}
#if __CMD_LINE__
DocMax;
/*

DumpSentences(
  "laicalis nisi hos quinque pericula et comminationes sunt dimittere sed nos perditus et nos cedere inferno."
  "[ quid quinque ] es [ [ Mortificatio animales ] et surreptio et [ peccare sexualiter ] et mendacium et [ alcohol illa inportet neglegentiam]]."
  "Nisi [ [ hos quinque pericula et comminationes ] sunt dimittere ] nisi [ nos sunt perditus ] et [ nos cedere inferno ]."
,
"Householder, unless these five dangers and threats are given up, one is said to be unethical, and one goes to hell\0"
"What five? Killing living creatures, stealing, committing sexual misconduct, lying, and using alcoholic drinks that cause negligence\0"
"Unless these five dangers and threats are given up, one is said to be unethical, and one goes to hell\0"
);
*/
/*DumpSentences(
	"Erema est symbolum  pro [ siccitas et infelix ]  de dormire animam."
        "[uva catervae] est [[symbolum pro schola scholarium]  quia [initiati surgere  conjuncte in solum rami]] ." 
	"Tu non oportet [ interficere animales vel furari vel potare alcohol ]."
	"Audio tibi et amo tibi."
	"namque [  Grinch sum cupere [coleum huius]].",
	"The desert is a symbol for the aridity and unproductivity of the unawakened consciousness.\0"
	"The grape cluster is a symbol for the school of adepts, for the initiates grow together upon a single branch\0"
	"You shouldn't kill living creatures, or steal,or lie, or drink alcohol.\0"
);*/

/*DumpSentences(
"sancti entia in decem regiones es."
"numerosus sicut [harenae [fluminis ganges]] es." // ...
"insimul adlaudant  [inopinabilissimus et [altissimam sanctus] dominum  Amitaiyus]."
"[[Omne ens] qui [audiant id nomen]] et [laetant in fidem]."
"cogitent eius solus semel."
"eorum devoveant [[meritum renato] [in illum sanctum agrum]]."
"adfecto [[renato illum]  et  [potiri renatum]  et [potiri salvationem]]." //
,
"All the Holy Ones in the ten directions,\0"
"as numerous as the sands of the Ganges River\0"
"together praise the inconceivable, supernal virtue of Lord Amitayus\0"
"All sentient beings who, having heard his Name, rejoice in faith,\0"
" think of him even once,\0"
"and sincerely devote the merit of virtuous practices to rebirth in that holy land,\0"
//aspiring to be reborn there, will attain rebirth and attain salvation. But excluded are those who have committed the five cardinal sins and violated the holy law."
);*/
/*
DumpSentences(
" [in principio] creavit Deus caelum et terram."
"[terra erat [inanis et vacua]] et [[tenebrae super faciem ]  et spiritus Dei ferebatur super aquas]."
"[dixitque Deus] quod [[fiat lux] et [facta est lux]]."
"et [[vidit Deus lucem] quod [esset bona]] et [divisit lucem ac tenebras]."
"[appellavitque quod [[lucem diem es] et [tenebras noctem es] ]]."
,
"In the beginning God created heaven, and earth.\0"
"And the earth was void and empty, and darkness was upon the face of the deep; and the spirit of God moved over the waters.\0"
"And God said: Be light made. And light was made.\0"
"And God saw the light that it was good; and he divided the light from the darkness.\0"
"And he called the light Day, and the darkness Night; and there was evening and morning one day. \0"
);
*/
//DumpSentences("Es [optumus situs] [interretialis finctus].","Is the best site of the false internet!");


//DumpSentences("Benedicere te. Spero potioris pacem aeternam et laetitiam.");
/*DumpSentences(
	"namque [sum ego [ cupere nigrum coleum]]."
);*/
/*DumpSentences(
"*[ omnis sancti entia in decem regiones] es.",
"Poop\0"
);*/
//
//DumpSentence("quomondo","es","tuum","sapor","[","camelus","lotii","]");;
//DumpSentence("[","tu","ne","cede","malis","]","sed","contra","audentior","ito"); 
//DumpSentence("Spero","potioris","pacem","aeternam","et","laetitiam");
//DumpSentence("nisi","[","canto","]","sed","audio");
//DumpSentence("laicalis","nisi","hos","quinque","pericula","et","comminationes","sunt","dimittere","sed","nos","perditus","et","nos","cedere","inferno");
//DumpSentence("[","quid","quinque","]","es","[","[","Mortificatio","animales","]","et","surreptio","et","[","peccare","sexualiter","]","et","mendacium","et","[","alcohol","illa","inportet","neglegentiam","]","]");
//DumpSentence("Nisi","[","[","hos","quinque","pericula","et","comminationes","]","sunt","dimittere","]","nisi","[","nos","sunt","perditus","]","et","[","nos","cedere","inferno","]");
//
/*DumpSentence("portat");
DumpSentence("portat","saxa","puella","in","aqua");
DumpSentence("cibum","et","aquam","portabo","ad","triclinium");
DumpSentence("cibum","portatis","et","aquam","gustant","sed","vinum","amamus");
DumpSentence("agricolae","saxa","invenient");
DumpSentence("servi","et","puellae","reginam","audiebant");
DumpSentence("in","triclinio","cibum","paramus");
DumpSentence("quomondo","aquam","portabis");
DumpSentence("quis","est");
DumpSentence("cum","amico","in","silva","ambulo");
DumpSentence("ex","silva","ad","villam","festinabo","et","cum","amico","in","cameram","ambulabo");
DumpSentence("nepos","noster","uxorem","cupit");
DumpSentence("non","edam","vivo","sed","ut","vivam","edo");*/
//Genesis 1
//DumpSentences("creavit terram  et terram");
//InteractView("edimus ut vivamus");
//InteractView("philosophia est vitae magistra");
//DumpSentences("assentatio  es [malus vitium]");
//DumpSentences("video hominem abire");
//InteractView("et [[tenebrae super faciem] abyssi] et [[spiritus Dei] ferebatur [super aquas]]");
//DumpSentences("tenebrae super faciem abyssi et spiritus Dei ferebatur super aquas");
//DumpSentences("[[tenebrae super faciem] abyssi] et [[spiritus Dei] ferebatur [super aquas]]");
//"si",
//DumpSentences("[Omne qui] ens audiant nomen.");
/*DumpSentences("spiritus Dei ferebatur super aquas");
DumpSentences(
"res finitus sunt."
"Formamentum sunt haut."
"Res creat e formamentis abditis."
"Animi sunt abditi."
"animos sunt mutationes [formamentorum].");*/
// Nroot's Doctrine 1
//DocClear;
//DumpSentences(//"Res  finitus sunt ."
/*	"Formamentum sunt haut."
	"Res creat e [formamentis abditis]."
	"Animi est abditi."
	"animos sunt mutationes formamentorum."
	"Mutatio formamentorum sunt  discursum."
	"tela tenet unus  fila ilico. [duo fila existit haut]  ubi [unus existat]."
	"sed fila existat juxta alius fila."
	"[[unus corpus] teneat haut [alius positum]]."
	"[corpus tenet diversum animos] quando [diversum positum existit]."*/
//	"[animus est juxta [diversum animos]] hac [tela tenet [diversum fila]."
//	"[idem animi ] sunt [[omnia animos] in [diversum positum]]."
	//);
//InteractView("decorum est pro patria mori");
//
//InteractView("in principio [creavit Deus [caelum et  terram]]");
//DumpSentences("in principio [creavit Deus [caelum et  terram]]");
//InteractView("Notitia est peior quam melior");
//DumpSentences("Notitia est peior quam melior");
//TrieAdd("Herodes",NOUN|NOMITIVE,"Herod");
//InteractView("tunc Herodes videns");
//DumpSentences("[[tunc Herodes videns] quoniam [inlusus esset a magis]] et [iratus est valde]");
// et mittens occidit omnes pueros qui erant in Bethleem et in omnibus finibus eius a bimatu et infra secundum tempus quod exquisierat a magis");
//DumpSentences("[Formamentum sunt haut] et [res sunt]");
//InteractView("tenebrae [super faciem] abyssi");
//InteractView("[res sunt haut]");
//DumpSentences("tenebrae super faciem");
//DumpSentences("[tenebrae super faciem] abyssi");
//InteractView("[[spiritus Dei] ferebatur  super aquas]");
//InteractView("Res sunt formamentis abditis.");
//InteractView("et [praeteriens [vidit hominem caecum a nativitate]].");
//Genesis 1
try DumpSentences("in principio [creavit Deus [terram et caelum]]");
catch
PutExcept(FALSE);
DumpSentences("Terra autem  erat inanis et vacua"); //, et tenebrae erant super faciem abyssi: et Spiritus Dei ferebatur super aquas
DumpSentences("et tenebrae erant super faciem abyssi"); //: et Spiritus Dei ferebatur super aquas
//John 9:1
//DumpSentences("et praeteriens [vidit hominem caecum a nativitate].");
//1st conjugation
DumpSentences("[non habeam   inimicitias aliis]. [res viventium] non habeat mecum inimicitias.","May I have no hostillity with others.\0May other living creatures have no hostility with me.\0");
DumpSentences("Dixitque Deus : Fiat lux");
DumpSentences("Terra autem erat [inanis et vacua] ,et  tenebris erant super faciem abyssi");
Break;
DocMax;

DumpSentences(
	"ingeniculo [dominum  liberandi] qui fui [ [nexionis vastatorem] et [sciendum omnia]]." // 
	"ita  habeamus [virtutem suum]."
        "[iustus [fides et mos et cognitio]] sunt semitam."
	"[[fides rei] reperire]  es [verum  fidem]."
	"[hic fides] surgat per discendum."
	"[[non animus] animusque nexioque libertasque motusque et dividere] componunt rem."
	"hi definiunt [[nomen et imaginem] et [potentiam et statum]]."
	"[septem cognitiones] colligunt rationem et sententiam."
	"[septem cognitiones] colligunt [ causam descriptumque habensque et [locum  nixa] diuturnitatemque partitamque]."
	"[septem haec] sunt [ existendum locum numerum  longitudinem tempus aetatemque et [cogitationem et comparandum]]."
	"[quinque genus cognitionum] sunt [sensum scriptum inobservatum divinationem omnisciensque]. "
	"hoc sunt [duo [verum cognitionem] generum]."
	"[duo primus] sunt visibilem cognitionem."
	"[hoc tres postremus] sunt [directum cognitum]."
	"[sensusque cogitareque meminisseque agnoscereque colligensque et reducere] sunt idem."
	"haec importat Sensum animamque."
	"[quattuor  sensitivorum] sunt [[sentientes allegationemque] iudiciaque et meminisse]."
	"[haec multa genera] sunt [[velocem occultatam incelebratam  perpetua oppositamque]=Adj@Adj]=Noun@Noun."
	"haec attributum sunt rerum."
	"Metus solum es fusca rem."
	"[[tongitio scripturarum]  praecedere [duo sensitivum  cognitionem]] sunt  duodecim partis."
        "[divinatio pariendus] habet [res vivum caeleste infernaque]."
        "[divinatio ex levare velamen] sunt en [hominibus  animalibusque] [sex  partes]  ."
	"lectio rei sunt [duo genera]."
	"[differentia de [lectionem rei et divinationem]]  sunt [puritatem certumque]."
	"[[lectio rei] divinatioque] dissidet [puritatem spatium scientem remque]."
	"[[tongitio scripturarum] et [tongitio sensitivus]] tenent [[sex omnes res] et [non effatos]]."
	"divinatio [tenet tantum] formam rei."
	"[spatium lectionis rei] es [[infinitum parvum res ] e divinationem ] ."
        "omnisciens habet simul [[omnia res] et [eum stata]]."
	"[unum usque quattuor [genus cognitionis]] teneat [unus anima]."
	"[[sensuum liberi divinationisque] cognitio] sit [cognitiones falsorum]."
	"[falsum cognitionis] propter [indigentiam iudicii inter [falsa et veritates]] es dementem."
	"[symbolicus vocalis compositum analyticus communis cetus directusque] sunt rationes."
,
	"I bow to the Lord of Liberation who is the destroyer of bondage and knower of all.\0"
        "So that I may have their Virtuees.\0" 	
	"Right Faith,Conduct and Knowledge are the path.\0"
	"Belief in discovered substances is correct faith.\0"
	"This faith is gotten through learning things.\0"
	"Reality is made of Soul,non-soul,movement and bondange,liberation and seperation\0"
	"These are defined by name,representation potentional and state\0"
	"The 7 knowledges are gained via knowledge and judgement.\0"
	"The 7 Knowledges are gained by description,ownsership,cause,resting place,duration,and dividing.\0"
	"These 7 are existence,location,number,measurement,time,timespan,thought at comparsion.\0"
	"The 5 classifications of the knowledges are senses,scripture,unseen,divination and all-knowing.\0"
	"These valid knowledges.\0"
	"The first 2 of them are seen knowledges.\0"
	"The last 3 of them are unseen knowledges.\0"
	"Senses,thinking,remembering,reducing and gathing are the seme.\0"
	"These are from senses and mind.\0"
	"The 4 classes of sensory knowledge are senses,speculation,judgement and recalling.\0"
	"More kinds are quick,hidden,uncelebrated,long-lasting and opposites.\0"
	"These are the attributes of matter.\0"
	"There is only fear of indistinct things.\0"
	"Scriptural knowledge of the 2 kinds is of 12 subdivisions.\0"
	"The divine knowledge at birth from sensory knowledge is  for hell and heaven creatures.\0"
	"The divine knowledge from lifting the veil is  of 6 kinds(in humans and animals).\0"
	"There are 2 kinds of telepathy.\0"
	"The difference of telepahy and divine knowledge are by purity and certianty.\0"
	"The difference is purity,space,knower and things.\0"
	"The reach of sensory knowledge is the 6 substacnces and their states.\0"
	"Divine knowledge has only the form of things.\0"
	"The scope of telepathy is a really small part of divine knowledge.\0"
	"Knowing all things uncludes their states too(at once).\0"
	"1 to 4 types of knowledge can be held by a soul.\0"
	"Senory knowledge,scriptural knowledge and divination may be false knowledges.\0"
	"False knowledge from a abscence of falsehood and reality is insaity.\0"
	"Representation,words,composite,anayltical comman straight and specific are the positions.\0"
//,"/WWW/Tattvarth1.DD"
);//et [prohibere et]18
#endif	
#endif