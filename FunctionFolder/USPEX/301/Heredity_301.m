function Heredity_301(Ind_No)

% Change: added multiparents heredity
% We will reselect parents, if USPEX cannot produce good Offspring within 100 attempts
% Last updated by Qiang Zhu (2013/10/16)
global  POOL_STRUC
global  ORG_STRUC
global  OFF_STRUC

info_parents = struct('parent', {}, 'fracFrac', {},'dimension', {},'offset', {}, 'enthalpy', {});

searching = 1;

Vector = zeros(1,length(ORG_STRUC.atomType));
for i = 1 : length(ORG_STRUC.atomType)
  Vector(i)= 2*str2num(covalentRadius(ceil(ORG_STRUC.atomType(i))));
end
minSlice = min(Vector);
maxSlice = max(Vector);
count = 1;
searching = 1;
while searching
    count = count + 1;
    if count > 50
       %disp('failed to do Heredity in 50 attempts, switch to Random');
       USPEXmessage(507,'',0);
       Random_301(Ind_No);
       break;
    end

   same = 1;
   while same 
        dimension = RandInt(1,1,[1,3]);  
        par_one = find (ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
        par_two = find (ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
        if par_one(end) ~= par_two(end)
           same = 0;
        end
   end

% two parents give many slabs, 
% 2 - every slab is chosen independently form previous

   goodHeritage = 0;
   goodLattice = 0;
   goodComposition = 0;
   securityCheck = 0;
   while goodHeritage + goodLattice + goodComposition ~=3
       securityCheck = securityCheck+1;
       offset=[];
       
       lat1=latConverter(POOL_STRUC.POPULATION(par_one(end)).LATTICE);
       lat2=latConverter(POOL_STRUC.POPULATION(par_two(end)).LATTICE);
       dimension = RandInt(1,1,[1,3]);
       
       if lat1(dimension) > (maxSlice+minSlice) & lat2(dimension) > (maxSlice+minSlice) & size(ORG_STRUC.numIons,1)>1
          % zebra-heredity
          parents = zeros(100,1);
          for i = 1 : 50
             parents(2*i)   = par_one(end);
             parents(2*i-1) = par_two(end);
          end         
          [numIons, numBlocks, potentialOffspring, potentialLattice,fracFrac,dimension,offset]= heredity_finalMP_var(parents, dimension);
       else
          [numIons, numBlocks, potentialOffspring, potentialLattice,fracFrac,dimension,offset]= heredity_final_var(par_one(end),par_two(end));
       end
          vol = det(potentialLattice);

% optimize the lattice      
          coord = potentialOffspring*potentialLattice; 
          [coord, potentialLattice] = optLattice(coord, potentialLattice);
          potentialOffspring = coord/potentialLattice;

        if sum(numIons) == 0
          goodHeritage = 0;
        else
          goodHeritage = distanceCheck(potentialOffspring, potentialLattice, numIons, ORG_STRUC.minDistMatrice);
          goodLattice = latticeCheck(potentialLattice);
          goodComposition = CompositionCheck(numBlocks);
        end

        if goodHeritage + goodLattice + goodComposition == 3
            OFF_STRUC.POPULATION(Ind_No).COORDINATES = potentialOffspring;
            OFF_STRUC.POPULATION(Ind_No).LATTICE = potentialLattice;
            OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
            OFF_STRUC.POPULATION(Ind_No).numBlocks = numBlocks;
            ID1 = POOL_STRUC.POPULATION(par_one(end)).Number;
            ID2 = POOL_STRUC.POPULATION(par_two(end)).Number;
            E1  = POOL_STRUC.POPULATION(par_one(end)).enthalpy;
            E2  = POOL_STRUC.POPULATION(par_two(end)).enthalpy;
            info_parents(1).parent = num2str([ID1 ID2]);
            info_parents.enthalpy = 0;
            fracFrac = [0 fracFrac 1];
            for i = 2:length(fracFrac)
               ratio=fracFrac(i)-fracFrac(i-1);
               if mod(i,2)==1
                  info_parents.enthalpy = info_parents.enthalpy+E1*ratio;
               else
                  info_parents.enthalpy = info_parents.enthalpy+E2*ratio;
               end
            end
            info_parents.fracFrac=fracFrac;
            info_parents.dimension=dimension;
            info_parents.offset=offset;
            OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
            OFF_STRUC.POPULATION(Ind_No).howCome = ' Heredity ';
            disp(['Structure ' num2str(Ind_No) ' generated by heredity']);
            searching=0;
        end

        if securityCheck > 100
            disp('Cannot produce good Offspring within 100 attempts')
            break;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% END CREATING Offspring with heredity %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
