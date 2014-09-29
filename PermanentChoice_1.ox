
struct PermanentChoice_1 : PermanentChoice {
	 decl Reset;		
     PermanentChoice_1(const L, const Target,const Reset);   
     Transit(const FeasA);									
     }

PermanentChoice_1 :: PermanentChoice_1(const L, const Target, const Reset)  {
	PermanentChoice_1(L, Target);	
	this.Reset = Reset;
    }

PermanentChoice_1 :: Transit(const FeasA) {
	return CV(Reset) ? return{<0>,ones(rows(FeasA),1)} : PermanentChoice::Transit(FeasA);
	}
