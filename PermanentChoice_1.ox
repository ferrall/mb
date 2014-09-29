/* This file is part of niqlow. Copyright (C) 2012 Christopher Ferrall */

struct PermanentChoice_1 : LaggedAction {

	 decl Target, Reset;		// declare needed constants
     PermanentChoice_1(const L, const Target,const Reset);   // declare needed members
     Transit(const FeasA);									// declare the constructor
     }

PermanentChoice_1 :: PermanentChoice_1(const L, const Target, const Reset)  {
	//initialize constants and members
	LaggedAction(L, Target);					// REQUIRED: at some point call the base class constructor
	this.Reset = Reset;
	//initialize more constants and members
    }

PermanentChoice_1 :: Transit(const FeasA) {
		// Compute vector of next states & matrix of transition probabilities
		// See documentation for explanation
		// return them as an array like this
	
	if(!Reset.v){
		if (!v) return LaggedAction::Transit(FeasA);
		return UnChanged(FeasA);
	}
	else{
//		if (!v) return LaggedAction::Transit(FeasA);
//		return UnChanged(FeasA);
		return{0,1}; //so if reset == 1, then return 0.  
	}
}

/*  Optional: define function to update actual values (every time a new solution is found).*/
//
//«VarName»::Update() {
//     actual = ... ;  //update actual quantity vector
//     }
