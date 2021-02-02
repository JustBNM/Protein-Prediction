function Heredity_000(Ind_No)

global POP_STRUC
global ORG_STRUC
global OFF_STRUC

  info_parents = struct('parent',{}, 'fracFrac', {},'dimension', {},'offset', {}, 'enthalpy', {});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CREATING Offspring with heredity %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching = 1;
count = 1;
while searching
    count = count + 1;
    if count > 50
       %disp('failed to do mutation in 50 attempts, switch to Random');
       USPEXmessage(508,'',0);
       Random_000(Ind_No);
       break;
    end
 % choose one set of parents
 % We select randomly a dimension used for the spacial criteria of the heredity
   dimension = RandInt(1,1,[1,3]);  
  if (ORG_STRUC.manyParents == 0) | (ORG_STRUC.manyParents > 1)  
     same = 1;
     safeguard = 1000;
    % make sure you don't choose twice the same structure for this heredity
    while same
        par_one = find (ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
        par_two = find (ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
     %%%%%%%%%%%%%%%%%%% here we only choose reasonable structure 
        ind1 = POP_STRUC.ranking(par_one(end));
        ind2 = POP_STRUC.ranking(par_two(end));
        if par_one(end) ~= par_two(end)
           same = 0;
	end
    end
     parents = zeros(100,1);
     for i = 1 : 50
        parents(2*i) = ind1;
        parents(2*i-1) = ind2;
     end

  else
   parents_rank = randperm(max(ORG_STRUC.tournament));
   parents = zeros(length(ORG_STRUC.tournament),1);
   parents_ind = zeros(length(POP_STRUC.ranking),1);
   j1 = 1;
   for i1 = 1:max(ORG_STRUC.tournament)
     par = find (ORG_STRUC.tournament > (parents_rank(i1)-1));
     if parents_ind(POP_STRUC.ranking(par(end))) == 0
        parents_ind(POP_STRUC.ranking(par(end))) = 1;
        parents(j1) = POP_STRUC.ranking(par(end));
        j1 = j1 + 1;
     end
   end
 % Take into account maxDistHeredity
    for i1 = 2 : length(ORG_STRUC.tournament)
        badParent = 0;
        for j1 = 1 : i1-1
            f1 = POP_STRUC.POPULATION(POP_STRUC.ranking(parents(i1))).FINGERPRINT;
            f2 = POP_STRUC.POPULATION(POP_STRUC.ranking(parents(j1))).FINGERPRINT;
            if cosineDistance(f1, f2, ORG_STRUC.weight) > ORG_STRUC.maxDistHeredity
               badParent = 1;
            end
        end
        if badParent
           c1 = parents(i1);
           for j1 = i1 : length(ORG_STRUC.tournament)-1
               parents(j1) = parents(j1+1);
           end
           parents(length(ORG_STRUC.tournament)) = c1;
        end
    end
  
  end

   %wait for suitable offspring (offspring fulfilling hard constraints)
   goodHeritage = 0;
   securityCheck = 0;
   while goodHeritage ~=1
      securityCheck = securityCheck+1;
      offset=[];
      if ORG_STRUC.manyParents == 0
         [numIons, potentialOffspring, potentialLattice,fracFrac,dimension,offset, fracLattice,parents1]= heredity_final_clusterMP([ind1, ind2]);
      else
         [numIons, potentialOffspring, potentialLattice,fracFrac,dimension,offset, fracLattice,parents1]= heredity_final_clusterMP(parents);
      end
      goodHeritage = distanceCheck(potentialOffspring, potentialLattice, numIons, ORG_STRUC.minDistMatrice);
      if goodHeritage == 1
         goodHeritage = checkConnectivity(potentialOffspring, potentialLattice, numIons);  %we also need to check the connectivity
      end
      if goodHeritage == 1
         OFF_STRUC.POPULATION(Ind_No).COORDINATES = potentialOffspring;
         OFF_STRUC.POPULATION(Ind_No).LATTICE = potentialLattice;
         OFF_STRUC.POPULATION(Ind_No).numIons = numIons;

         fracFrac = [0 fracFrac 1];
         enthalpy = 0;
         ID = [];
         for i = 2:length(fracFrac)
             ID= [ID POP_STRUC.POPULATION(parents(i-1)).Number];
             E = POP_STRUC.POPULATION(parents(i-1)).Enthalpies(end);
             ratio=fracFrac(i)-fracFrac(i-1);
             enthalpy = enthalpy+E*ratio;
         end
         info_parents(1).parent = num2str(ID);
         info_parents.enthalpy  = enthalpy(end);
         info_parents.enthalpy  = info_parents.enthalpy/sum(numIons);
         info_parents.fracFrac  = fracFrac;
         info_parents.dimension = dimension;
         info_parents.offset    = offset;
         OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
         OFF_STRUC.POPULATION(Ind_No).howCome = 'Heredity';
         
         disp(['Structure ' num2str(Ind_No) ' generated by heredity']);
         searching=0;
     end

     if securityCheck > 100
         %we won't wait for a good offspring forever, will we?
         break
     end
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% END CREATING Offspring with heredity %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
