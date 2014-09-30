
struct PermanentChoiceWithReset : PermanentChoice {
	 decl Reset;		
     PermanentChoiceWithReset(L,Target,Reset);   
     Transit(FeasA);									
     }

PermanentChoiceWithReset :: PermanentChoiceWithReset(L, Target, Reset)  {
	PermanentChoice(L, Target);	
	this.Reset = Reset;
    }

PermanentChoiceWithReset :: Transit(FeasA) {
        t.v = v;   // synchronize base variable value
	decl v = FeasA[][Reset.pos].!=0, t = PermanentChoice::Transit(FeasA);
	if (any(v)) {                       //reset is feasible
		if (any(t[Qi]==0))          //some regular transitions are 0, replace prob.
		    return { t[Qi], v+(1-v).*t[Qrho] }; 
		return {0~t[Qi],v~t[Qrho]};  // append 0 transition in front of feasible list
		}
	return t;  //reset is infeasible
	}
