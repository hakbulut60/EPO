function [BestPos, BestFit, Curve] = EPO(Npop, MaxIt, lb, ub, nD, fobj)

%% Parameters
pCR = 0.2;
Q = 0.67;
Beta = 2;
PF = [0.5 0.5 0.3];

step_initial = 1;
step_final = 0.01;

explore_prob_initial = 0.5;
explore_prob_final = 0.3;

momentum_factor = 0.7;

% Robustluk kontrolü
if Npop < 7
    error('Population size must be at least 7 for EPO algorithm');
end

%% Initialization
pop = lb + rand(Npop, nD) .* (ub - lb);
fit = zeros(Npop, 1);

for i = 1:Npop
    fit(i) = fobj(pop(i, :));
end

[BestFit, idx] = min(fit);
BestPos = pop(idx, :);

prev_best = BestPos;
Curve = zeros(MaxIt, 1);

UnSelected = [1 1];
F3_Explore = 0;
F3_Exploit = 0;
Seq_Time_Explore = ones(1, 3);
Seq_Time_Exploit = ones(1, 3);
Seq_Cost_Explore = ones(1, 3);
Seq_Cost_Exploit = ones(1, 3);
PF_F3 = [];
Flag_Change = 1;

%% First 3 Iterations (Unexperienced Phase)
Costs_Explor = zeros(1, 3);
Costs_Exploit = zeros(1, 3);
Initial_BestFit = BestFit;

for Iter = 1:3
    
    prev_best = BestPos;
    
    % Exploration Phase
    [pop, fit, explor_best, explor_best_fitness, pCR] = exploration_phase(pop, fit, BestPos, prev_best, ...
        Npop, nD, lb, ub, fobj, pCR, step_initial, step_final, explore_prob_initial, ...
        explore_prob_final, momentum_factor, MaxIt, Iter);
    Costs_Explor(Iter) = explor_best_fitness;
    
    % Exploitation Phase
    [pop, fit, exploit_best, exploit_best_fitness] = exploitation_phase(pop, fit, BestPos, ...
        Npop, nD, lb, ub, fobj, Q, Beta, step_initial, step_final, MaxIt, Iter);
    Costs_Exploit(Iter) = exploit_best_fitness;
    
    % Update Best
    if explor_best_fitness < BestFit
        BestFit = explor_best_fitness;
        BestPos = explor_best;
    end
    if exploit_best_fitness < BestFit
        BestFit = exploit_best_fitness;
        BestPos = exploit_best;
    end
    
    Curve(Iter) = BestFit;
    
end

%% Hyper Initialization
Seq_Cost_Explore(1) = abs(Initial_BestFit - Costs_Explor(1));
Seq_Cost_Exploit(1) = abs(Initial_BestFit - Costs_Exploit(1));
Seq_Cost_Explore(2) = abs(Costs_Explor(2) - Costs_Explor(1));
Seq_Cost_Exploit(2) = abs(Costs_Exploit(2) - Costs_Exploit(1));
Seq_Cost_Explore(3) = abs(Costs_Explor(3) - Costs_Explor(2));
Seq_Cost_Exploit(3) = abs(Costs_Exploit(3) - Costs_Exploit(2));

for i = 1:3
    if Seq_Cost_Explore(i) ~= 0
        PF_F3(end+1) = Seq_Cost_Explore(i);
    end
    if Seq_Cost_Exploit(i) ~= 0
        PF_F3(end+1) = Seq_Cost_Exploit(i);
    end
end

% Score calculations
F1_Explor = PF(1) * (Seq_Cost_Explore(1) / Seq_Time_Explore(1));
F1_Exploit = PF(1) * (Seq_Cost_Exploit(1) / Seq_Time_Exploit(1));
F2_Explor = PF(2) * sum(Seq_Cost_Explore) / sum(Seq_Time_Explore);
F2_Exploit = PF(2) * sum(Seq_Cost_Exploit) / sum(Seq_Time_Exploit);

Score_Explore = PF(1) * F1_Explor + PF(2) * F2_Explor;
Score_Exploit = PF(1) * F1_Exploit + PF(2) * F2_Exploit;

%% Experienced Phase
for Iter = 4:MaxIt
    
    prev_best = BestPos;
    
    if Score_Explore > Score_Exploit
        % Exploration
        SelectFlag = 1;
        [pop, fit, new_best, new_best_fitness, pCR] = exploration_phase(pop, fit, BestPos, prev_best, ...
            Npop, nD, lb, ub, fobj, pCR, step_initial, step_final, explore_prob_initial, ...
            explore_prob_final, momentum_factor, MaxIt, Iter);
        Count_select = UnSelected;
        UnSelected(2) = UnSelected(2) + 1;
        UnSelected(1) = 1;
        F3_Explore = PF(3);
        F3_Exploit = F3_Exploit + PF(3);
        Seq_Cost_Explore(3) = Seq_Cost_Explore(2);
        Seq_Cost_Explore(2) = Seq_Cost_Explore(1);
        Seq_Cost_Explore(1) = abs(BestFit - new_best_fitness);
        if Seq_Cost_Explore(1) ~= 0
            PF_F3(end+1) = Seq_Cost_Explore(1);
        end
        if new_best_fitness < BestFit
            BestPos = new_best;
            BestFit = new_best_fitness;
        end
    else
        % Exploitation
        SelectFlag = 2;
        [pop, fit, new_best, new_best_fitness] = exploitation_phase(pop, fit, BestPos, ...
            Npop, nD, lb, ub, fobj, Q, Beta, step_initial, step_final, MaxIt, Iter);
        Count_select = UnSelected;
        UnSelected(1) = UnSelected(1) + 1;
        UnSelected(2) = 1;
        F3_Explore = F3_Explore + PF(3);
        F3_Exploit = PF(3);
        Seq_Cost_Exploit(3) = Seq_Cost_Exploit(2);
        Seq_Cost_Exploit(2) = Seq_Cost_Exploit(1);
        Seq_Cost_Exploit(1) = abs(BestFit - new_best_fitness);
        if Seq_Cost_Exploit(1) ~= 0
            PF_F3(end+1) = Seq_Cost_Exploit(1);
        end
        if new_best_fitness < BestFit
            BestPos = new_best;
            BestFit = new_best_fitness;
        end
    end
    
    if Flag_Change ~= SelectFlag
        Flag_Change = SelectFlag;
        Seq_Time_Explore(3) = Seq_Time_Explore(2);
        Seq_Time_Explore(2) = Seq_Time_Explore(1);
        Seq_Time_Explore(1) = Count_select(1);
        Seq_Time_Exploit(3) = Seq_Time_Exploit(2);
        Seq_Time_Exploit(2) = Seq_Time_Exploit(1);
        Seq_Time_Exploit(1) = Count_select(2);
    end
    
    % Update scores
    F1_Explor = PF(1) * (Seq_Cost_Explore(1) / (Seq_Time_Explore(1) + 1e-12));
    F1_Exploit = PF(1) * (Seq_Cost_Exploit(1) / (Seq_Time_Exploit(1) + 1e-12));
    F2_Explor = PF(2) * sum(Seq_Cost_Explore) / (sum(Seq_Time_Explore) + 1e-12);
    F2_Exploit = PF(2) * sum(Seq_Cost_Exploit) / (sum(Seq_Time_Exploit) + 1e-12);
    
    % Update Mega values
    if Score_Explore > Score_Exploit
        Mega_Explor = 0.99;
        Mega_Exploit = max(0.99 - 0.01 * (Iter / MaxIt), 0.01);
    else
        Mega_Explor = max(0.99 - 0.01 * (Iter / MaxIt), 0.01);
        Mega_Exploit = 0.99;
    end
    
    lmn_Explore = 1 - Mega_Explor;
    lmn_Exploit = 1 - Mega_Exploit;
    
    if ~isempty(PF_F3)
        min_PF_F3 = min(PF_F3);
    else
        min_PF_F3 = 1;
    end
    
    Score_Explore = Mega_Explor * F1_Explor + Mega_Explor * F2_Explor + ...
        lmn_Explore * (min_PF_F3 * F3_Explore);
    Score_Exploit = Mega_Exploit * F1_Exploit + Mega_Exploit * F2_Exploit + ...
        lmn_Exploit * (min_PF_F3 * F3_Exploit);
    
    Curve(Iter) = BestFit;
    
end

end

%% Helper Functions

function [pop, fit, best_pos, best_fit, pCR] = exploration_phase(pop, fit, BestPos, prev_best, ...
    Npop, nD, lb, ub, fobj, pCR, step_initial, step_final, explore_prob_initial, ...
    explore_prob_final, momentum_factor, MaxIt, Iter)

step = step_initial * (step_final / step_initial) ^ (Iter / MaxIt);
PCR = 1 - pCR;
p = PCR / Npop;

for i = 1:Npop
    x = pop(i, :);
    
    % Python ile birebir aynı indeks seçimi
    A = randperm(Npop);
    A(A == i) = [];
    A = A(1:6);
    
    a = A(1); b = A(2); c = A(3);
    d = A(4); e = A(5); f = A(6);
    
    G = 2 * rand() - 1;
    
    explore_prob = explore_prob_initial - ...
        (explore_prob_initial - explore_prob_final) * (Iter / MaxIt);
    
    if rand() < explore_prob
        % Enhanced exploration with momentum
        momentum = BestPos - prev_best;
        if rand() < momentum_factor && any(momentum ~= 0)
            move = momentum + 0.3 * randn(1, nD);
        else
            move = randn(1, nD);
        end
        y = x + step * move;
    else
        term1 = pop(a, :) - pop(b, :);
        term2 = (pop(c, :) - pop(d, :)) - (pop(e, :) - pop(f, :));
        y = pop(a, :) + G * term1 + G * (term1 - term2);
    end
    
    y = max(min(y, ub), lb);
    
    z = x;
    j0 = randi(nD);
    for j = 1:nD
        if j == j0 || rand() <= pCR
            z(j) = y(j);
        end
    end
    
    new_fit = fobj(z);
    if new_fit < fit(i)
        pop(i, :) = z;
        fit(i) = new_fit;
    else
        % İYİLEŞTİRME: pCR değerini 1 ile sınırla
        pCR = min(pCR + p, 1);
    end
end

[best_fit, idx] = min(fit);
best_pos = pop(idx, :);

end

function [pop, fit, best_pos, best_fit] = exploitation_phase(pop, fit, BestPos, ...
    Npop, nD, lb, ub, fobj, Q, Beta, step_initial, step_final, MaxIt, Iter)

step = step_initial * (step_final / step_initial) ^ (Iter / MaxIt);

for i = 1:Npop
    x = pop(i, :);
    
    beta1 = 2 * rand();
    beta2 = randn(1, nD);
    w = randn(1, nD);
    v = randn(1, nD);
    
    F1 = randn(1, nD) .* exp(2 - Iter * (2 / MaxIt));
    F2 = w .* v.^2 .* cos(2 * rand() * w);
    
    % İYİLEŞTİRME: Daha explicit boyut belirtme
    mbest = mean(pop, 1);
    R_1 = 2 * rand() - 1;
    S1 = (2 * rand() - 1 + randn(1, nD));
    S2 = F1 .* R_1 .* pop(i, :) + F2 .* (1 - R_1) .* BestPos;
    VEC = S2 ./ (S1 + 1e-12);
    
    best_candidate = [];
    best_candidate_fitness = inf;
    
    % Candidate 1: VEC based
    if rand() <= 0.5
        if rand() > Q
            rand_sol = pop(randi(Npop), :);
            NewSol = BestPos + beta1 * exp(beta2) .* (rand_sol - pop(i, :));
        else
            NewSol = beta1 * VEC - BestPos;
        end
    else
        r1 = randi(Npop);
        if rand() < 0.5
            signv = -1;
        else
            signv = 1;
        end
        NewSol = (mbest .* pop(r1, :) - signv * pop(i, :)) / (1 + Beta * rand());
    end
    NewSol = max(min(NewSol, ub), lb);
    new_fit = fobj(NewSol);
    if new_fit < best_candidate_fitness
        best_candidate = NewSol;
        best_candidate_fitness = new_fit;
    end
    
    % Generate additional local candidates (5 local candidates)
    % Candidate 2: Random perturbation
    cand = x + step * randn(1, nD);
    cand = max(min(cand, ub), lb);
    cand_fit = fobj(cand);
    if cand_fit < best_candidate_fitness
        best_candidate = cand;
        best_candidate_fitness = cand_fit;
    end
    
    % Candidate 3: Move toward best
    cand = x + step * (BestPos - x);
    cand = max(min(cand, ub), lb);
    cand_fit = fobj(cand);
    if cand_fit < best_candidate_fitness
        best_candidate = cand;
        best_candidate_fitness = cand_fit;
    end
    
    % Candidate 4: One-hot perturbation
    onehot = zeros(1, nD);
    onehot(randi(nD)) = 1;
    cand = x + step * onehot;
    cand = max(min(cand, ub), lb);
    cand_fit = fobj(cand);
    if cand_fit < best_candidate_fitness
        best_candidate = cand;
        best_candidate_fitness = cand_fit;
    end
    
    % Candidate 5: Multiplicative perturbation
    cand = x .* (1 + step * randn(1, nD));
    cand = max(min(cand, ub), lb);
    cand_fit = fobj(cand);
    if cand_fit < best_candidate_fitness
        best_candidate = cand;
        best_candidate_fitness = cand_fit;
    end
    
    % Candidate 6: Uniform perturbation
    cand = x + step * (2 * rand(1, nD) - 1);
    cand = max(min(cand, ub), lb);
    cand_fit = fobj(cand);
    if cand_fit < best_candidate_fitness
        best_candidate = cand;
        best_candidate_fitness = cand_fit;
    end
    
    if best_candidate_fitness < fit(i)
        pop(i, :) = best_candidate;
        fit(i) = best_candidate_fitness;
    end
end

[best_fit, idx] = min(fit);
best_pos = pop(idx, :);

end
