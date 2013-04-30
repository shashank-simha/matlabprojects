function [A,b,numRows_Aeq,numRows_AInEq] = getConstraints(numEdges,jEdges,...
                        edges2pixels,jDirectionalScores,offEdgeListIDs,onEdgeListIDs)
% returns equality and inequality constraints
% equality constraints:
%   each edge should be either active or inactive
%   each node should be either active or inactive
%   active nodes should have exactly one active configuration with 2 active
%   edges out of all possible active configurations for that node -
%   (closedness constraint)
% inequality constraint
%   each active node should have an active edge pair of which the
%   multiplication of the outwardness score should be negative i.e. one
%   edge should be inwards and the other should be outwards

withDirectionalConstraint = 1; % 1 to enable directionality constraint
withClosednessConstraint = 1; % 1 to enable closedness constraint (old)
withEdgeNodeCoherenceConstraint = 1; % 1 to enable
withOffEdgesConstraint = 1; % 1 to enable
withOnEdgesConstraint = 1; % 1 to enable

[~, numJtypes] = size(jEdges);
% type 1 is J2 - junction with just 2 edges
nodeTypeStats = zeros(numJtypes,2);
% each row corresponds to a junction type. row 1: type 1 (J2)
% column 1: n.o. junction nodes of this type
% column 2: n.o. edge pair combinations to be activated
totJunctionVar = zeros(numJtypes,1); % stores the number of coefficients for each type of J
totActiveJunctionConfs = zeros(numJtypes,1);
for i=1:numJtypes
    jEdges_i = jEdges{i};
    if(jEdges_i==0)
        % no junctions of this type
        nodeTypeStats(i,1) = 0;
        nodeTypeStats(i,2) = 0;
        totJunctionVar(i) = 0;
        totActiveJunctionConfs(i) = 0;
    else
        [numJ_i,numEdges_i] = size(jEdges_i);
        nodeTypeStats(i,1) = numJ_i;
        nodeTypeStats(i,2) = numEdges_i;
        numEdgeCombinations = nchoosek(numEdges_i,2);
        totJunctionVar(i) = numJ_i.*(numEdgeCombinations + 1); % 1 for the inactive node
        totActiveJunctionConfs(i) = numJ_i.*numEdgeCombinations;
        % clear nodeAngleCost_i
    end
end

% number of equations for each catagory
numEdgeActEqns = numEdges;
numJunctionActEquns = sum(nodeTypeStats(:,1));  % number of junctions
if(withClosednessConstraint)
    numClosednessEqns = sum(nodeTypeStats(:,1));    % num of junctions
else
    numClosednessEqns = 0;
end
if(withOffEdgesConstraint)
    numOffEdgegs = numel(offEdgeListIDs);
    if(numOffEdgegs>0)
        numOffEdgesEqns = 1;
    else
        numOffEdgesEqns = 0;
        withOffEdgesConstraint = 0;
    end
else
    numOffEdgesEqns = 0;
end
if(withOnEdgesConstraint)
    numOnEdgegs = numel(onEdgeListIDs);
    if(numOnEdgegs>0)
        numOnEdgesEqns = 1;
    else
        numOnEdgesEqns = 0;
        withOnEdgesConstraint = 0;
    end
else
    numOnEdgesEqns = 0;
end
if(withEdgeNodeCoherenceConstraint)
    numCoherenceEqns = sum(totActiveJunctionConfs); % num of active jn configs
else
    numCoherenceEqns = 0;
end
if(withDirectionalConstraint)
    numDirectionalEqns = sum(nodeTypeStats(:,1));    % num of junctions
else
    numDirectionalEqns = 0;
end

% num cols of Aeq = 2*numEdges + sum_j(numNodes_j*numCombinations+1)
numCols_Aeq = 2*numEdges + sum(totJunctionVar); 
% num rows of Aeq = numEdges + 2*numJ

% if(withClosednessConstraint)
%     numRows_Aeq = numEdges + sum(nodeTypeStats(:,1))*2 + sum(totActiveJunctionConfs);
% else
%     numRows_Aeq = numEdges + sum(nodeTypeStats(:,1)) + sum(totActiveJunctionConfs);
% end
% if(withDirectionalConstraint)
%     % num rows of inequality constraints = number of junctions
%     numRows_AInEq = sum(nodeTypeStats(:,1));
%     % totRows_A = numRows_Aeq + numRows_AInEq;
% else
%     numRows_AInEq = 0;
%     totRows_A = numRows_Aeq + numRows_AInEq;
% end

numRows_Aeq = numEdgeActEqns + numJunctionActEquns + numClosednessEqns +...
                numOffEdgesEqns + numOnEdgesEqns;
numRows_AInEq = numCoherenceEqns + numDirectionalEqns;
totRows_A = numRows_Aeq + numRows_AInEq;
A = zeros(totRows_A,numCols_Aeq);
%% b
b = zeros(totRows_A,1);
rowStart = 1;
rowEnd = numEdges + sum(nodeTypeStats(:,1));
b(rowStart:rowEnd) = 1; % node and edge activation
if(withClosednessConstraint)
    rowStart = rowEnd + 1;
    rowEnd = rowStart - 1 + numClosednessEqns;
    b(rowStart:rowEnd) = 0;
end
if(withOffEdgesConstraint)
    rowStart = rowEnd + 1;
    rowEnd = rowStart - 1 + numOffEdgesEqns;
    b(rowStart:rowEnd) = 0; 
end
if(withOnEdgesConstraint)
    rowStart = rowEnd + 1;
    rowEnd = rowStart - 1 + numOnEdgesEqns;
    b(rowStart:rowEnd) = 0; 
end
if(withEdgeNodeCoherenceConstraint)
    rowStart = rowEnd + 1;
    rowEnd = rowStart - 1 + numCoherenceEqns;
    b(rowStart:rowEnd) = 2; % less than
end
if(withDirectionalConstraint)
    rowStart = rowEnd + 1;
    rowEnd = rowStart - 1 + numDirectionalEqns;
    b(rowStart:rowEnd) = 0; % less than    
end
%% activation/inactivation constraints for each edge
j = 1;
for i=1:numEdges
    A(i,j:(j+1)) = 1;
    j = j+2;
end

%% activation/inactivation constraints for each junction node
colStop = numEdges*2;
rowStop = numEdges;
for jType = 1:numJtypes
    % for each junction type
    numNodes_j = nodeTypeStats(jType,1);
    numEdgePJ = jType + 1;      % number of edges per junction
    numCoef = nchoosek(numEdgePJ,2) + 1; % num edge pair combinations + inactivation  
    rowStart = rowStop + 1; 
    rowStop = rowStart - 1 + numNodes_j;
    for row=rowStart:rowStop
        colStart = colStop + 1;
        colStop = colStart - 1 + numCoef;
        A(row,colStart:colStop) = 1;
    end    
end

% % J3
% j = numEdges*2+1;
% for i=(numEdges+1):(numEdges+numJ3)
%     Aeq(i,j:(j+3)) = 1;
%     j = j+4;
% end
% % J4
% j = numEdges*2+numJ3*4+1;
% for i=(numEdges+numJ3+1):(numEdges+numJ3+numJ4)
%     Aeq(i,j:(j+6)) = 1;
%     j = j+7;
% end

%% closedness constraints
if(withClosednessConstraint)
    % for each node, either exactly two edges should be active (active node) or
    % all the edges should be inactive (inactive node)
    % numNodesTot = sum(nodeTypeStats(:,1));
    % rowStop = numEdges + numNodesTot;
    jColIdStop = numEdges*2;
    for jType=1:numJtypes
        % for each junction type
        % for each node, get the indices of the activeState edge variables
        jEdges_j = jEdges{jType};
        jEdgesOrderedInd_j = jEdges_j; % initializing
        % jEdges_j: the edge labels here follow the initial indexing. However,
        % the order of edges considered is slightly different to that due to
        % the removal of self edges and dangling edges. the edgeID->colInd of
        % the edge should be determined using the entries of the 1st column of
        % edges2pixels. This row number gives the edgeId to be used here.

        numNodes_j = nodeTypeStats(jType,1);
        if(numNodes_j~=0)
            for i=1:numNodes_j
                % for each node, get the edges from jEdges_j
                % for each edge, get the row number from edges2pixels
                % add to jEdgesInd_j
                edgeIDs = jEdges_j(i,:);
                for m=1:numel(edgeIDs)
                   edgeOrderInd = find(edges2pixels(:,1)==edgeIDs(m)); 
                   jEdgesOrderedInd_j(i,m) = edgeOrderInd; 
                end
            end   
            activeEdgeColInds = jEdgesOrderedInd_j.*2;     % edges are represented in pairs of state variables
                                                % the second element corresponds to
                                                % the active state
            % for each junction for type j
            rowStart = rowStop + 1;
            rowStop = rowStart - 1 + numNodes_j;
            k = 1;
            for row=rowStart:rowStop
                A(row,activeEdgeColInds(k,:)) = 1; 
                k = k + 1;
                numEdges_i = nodeTypeStats(jType,2);
                numEdgeCombinations_j = nchoosek(numEdges_i,2);
                jColIdStart = jColIdStop + 2;
                jColIdStop = jColIdStart + numEdgeCombinations_j - 1;
                jIds = jColIdStart:jColIdStop;
                A(row,jIds) = -2;               % refer closedness constraint formulation
                % jColIdStop = jColIdStop + numEdgeCombinations_j;
            end
        end

    end
end
%% Equality constraint - turn off misoriented edges
if(withOffEdgesConstraint)
    % numOffEdges = numel(offEdgeListIDs);        % number of edges to be turned off
    offEdges_activeStateInd = offEdgeListIDs .* 2;
    % offEdges_inactiveStateInd = offEdges_activeStateInd - 1;
    rowStop = rowStop + 1;
    A(rowStop,offEdges_activeStateInd) = 1; % corresponding b should  be 0
end
%% Equality constraint - turn on edges with strong unary OFR
if(withOnEdgesConstraint)
    onEdges_inActiveStateInd = onEdgeListIDs .* 2 - 1;
    rowStop = rowStop + 1;
    A(rowStop,onEdges_inActiveStateInd) = 1; % corresponding b should  be 0
end
%% inequality constraint - coherence between activeNodeStates and the corresponding active edges
% this is required since only a particular pair of edges out of all the
% possible edges connected to a node should be activated, if the node is active 
% NB. closed constraint is also implicitly enforced with this.
if(withEdgeNodeCoherenceConstraint)
    jConfStateInd = numEdges*2;
    for jType=1:numJtypes
        numNodes_j = nodeTypeStats(jType,1); % number of nodes of this type
        if(numNodes_j~=0)
            numEdgesPerNode = jType + 1;
            edgeNumVec = 1:numEdgesPerNode;
            edgeCombinationVec = nchoosek(edgeNumVec,2);
            numActiveCombinations = size(edgeCombinationVec,1); 
            jEdges_j = jEdges{jType};
            jEdgesOrderedInd_j = jEdges_j; % initializing - to store the edgeListIDs
            for i=1:numNodes_j
                % for each node of this junction type
                edgeIDs = jEdges_j(i,:);
                for m=1:numel(edgeIDs)
                    % for each edge connected to this node
                    edgeOrderInd = find(edges2pixels(:,1)==edgeIDs(m));  % edgeListIDs
                    jEdgesOrderedInd_j(i,m) = edgeOrderInd; 
                end
                edgeActiveStatesInd_i = jEdgesOrderedInd_j(i,:) .*2;
                %edgeInactiveStatesInd_i = edgeActiveStatesInd_i - 1;
                % entry for the inactive state of the node
                % nothing
                % for the active states of the node
                jConfStateInd = jConfStateInd + 1; % now points to the inactive state
                for m=1:numActiveCombinations
                    % for each active configuration of this node
                    jConfStateInd = jConfStateInd + 1;
                    rowStop = rowStop + 1;
                    A(rowStop,jConfStateInd) = -2;  % coefficient for the node active state
                    % edge coefficients
                    edge1id = edgeCombinationVec(m,1);
                    edge1_activeStateInd = edgeActiveStatesInd_i(edge1id);
                    A(rowStop,edge1_activeStateInd) = 1;
                    edge2id = edgeCombinationVec(m,2);
                    edge2_activeStateInd = edgeActiveStatesInd_i(edge2id);
                    A(rowStop,edge2_activeStateInd) = 1;
                end

            end
        end
    end
end
%% Inequality constraint - enforcing inEdge+outEdge at active junctions
if(withDirectionalConstraint)
    jColIdStop = numEdges*2; % next, start with the first inactive node state
    % rowStop = numEdges + numNodesTot*2;
    for jType=1:numJtypes
        % for each junction type, get the indices of the junction variables
        % set inactiveState variable to -1
        % for each active configuration of the node, get the corresponding
        % directional score
        dirScore_j = jDirectionalScores{jType};
        numNodes_j = nodeTypeStats(jType,1); % number of nodes of this type
        if(numNodes_j~=0)
            for i=1:numNodes_j
                numEdgesPNode = jType + 1;
                numActiveConfigs = nchoosek(numEdgesPNode,2);
                rowStop = rowStop + 1;
                jColIdStart = jColIdStop + 1;
                A(rowStop,jColIdStart) = -1; % coefficient for node inactive state
                jColIdStop = jColIdStart + numActiveConfigs;
                jColIdStart = jColIdStart + 1;            
                A(rowStop,jColIdStart:jColIdStop) = dirScore_j(i,:);
            end
        end
    end
end