function [GeneticInfomation] = ClonalEvolve(GeneticInfomation)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
N = size(GeneticInfomation, 1);
G = size(GeneticInfomation, 2);
H = 1;
bar(1:size(GeneticInfomation, 2), Diversity(GeneticInfomation));
for j = 1:10
    for n=1:N
        F = sum(GeneticInfomation(n, :))/G;
        for m = 1:G
            if rand(1) < (1/F)*(H/G)
                GeneticInfomation(n, m) = not(GeneticInfomation(n, m));
            end
        end
        
    end
    figure
    bar(1:size(GeneticInfomation, 2), Diversity(GeneticInfomation));
end
end

