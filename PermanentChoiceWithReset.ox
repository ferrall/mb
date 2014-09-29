
struct PermanentChoiceWithReset : PermanentChoice {
	 decl Reset;		
     PermanentChoiceWithReset(const L, const Target,const Reset);   
     Transit(const FeasA);									
     }

PermanentChoiceWithReset :: PermanentChoiceWithReset(const L, const Target, const Reset)  {
	PermanentChoice(L, Target);	
	this.Reset = Reset;
    }

PermanentChoiceWithReset :: Transit(const FeasA) {
	decl v = FeasA[][Reset.pos];
	return CV(v) ? {<0>,ones(rows(FeasA),1)} : PermanentChoice::Transit(FeasA);
	}
