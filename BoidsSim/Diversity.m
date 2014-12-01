function [A] = Diversity(GeneticInfomation)
%Computes the Genetic Diversity of an input Matrix 
%   Detailed explanation goes here
A = sum(GeneticInfomation, 1);
b = size(GeneticInfomation, 1);
c=bsxfun(@plus, -A, b);
end

