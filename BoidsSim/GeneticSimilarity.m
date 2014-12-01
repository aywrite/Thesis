N = 50;
G = 10;
%Generate N sets of DNA of length G and stores it in the Matrix GI
R = rand(G, N);
GI = R>0.5;
%Compute the N^2 similarity between each Agent
AverageSimilarity = zeros(N, 1);
for n = 1:N
    for m = 1:N
        if m~=n %do not compare against self
            localSimilarity = sum(GI(:,m) == GI(:,n));
            AverageSimilarity(n) = AverageSimilarity(n) + localSimilarity;
        end
    end
end
AverageSimilarity = AverageSimilarity/(N-1)/G;
sum(AverageSimilarity)/N