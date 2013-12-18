require "guided_local_search/version"

module GuidedLocalSearch
  class GuidedLocalSearch
    # get line distance between cities
    def euc_2d(c1, c2)
      Math.sqrt((c1[0] - c2[0]) ** 2 + (c1[1] - c2[1]) ** 2).round
    end

    # shake cities (random permute)
    def random_permutation(cities)
      shake = Array.new(cities.size){|i| i}
      shake.each_index do |i|
        r = rand(shake.size - i) + i
        shake[r], shake[i] = shake[i], shake[r]
      end
      shake
    end

    # shake in range
    def stochastic_two_opt(shake)
      sh = Array.new(shake)
      c1, c2 = rand(sh.size), rand(sh.size)
      pool = [c1]
      pool << ((c1 == 0) ? sh.size - 1 : c1 + 1)
      pool << ((c1 == sh.size -1) ? 0 : c1 - 1)
      c2 = rand(sh.size) while pool.include? c1
      c1, c2 = c2, c1 if c2 < c1
      sh[c1...c2] = sh[c1...c2].reverse
      sh
    end

    # get augmented cost
    def augmented_cost(shake, penalties, cities, modifier)
      distance, augmented = 0, 0
      shake.each_with_index do |c1, i|
        c2 = (i == shake.size - 1) ? shake[0] : shake[i + 1]
        c1, c2 = c2, c1 if c2 < c1
        d = euc_2d(cities[c1], cities[c2])
        distance += d
        augmented += d + (modifier * penalties[c1][c2])
      end
      [distance, augmented]
    end

    # get shake cost
    def cost(cand, penalties, cities, modifier)
      cost, acost = augmented_cost cand[:vector], penalties, cities, modifier
      cand[:cost], cand[:aug_cost] = cost, acost
    end

    # get utilities
    def feature_utilities(penal, cities, shake)
      utilities = Array.new(shake.size, 0)
      shake.each_with_index do |c1, i|
        c2 = (i == shake.size -1) ? shake[0] : shake[i + 1]
        c1, c2 = c2, c1 if c2 < c1
        # +++ metric utilities
        utilities[i] = euc_2d cities[c1], cities[c2] / (1.0 + penal[c1][c2])
      end
      utilities
    end

    # update penalties
    def update_penalties(penalties, cities, shake, utilities)
      max = utilities.max()
      shake.each_with_index do |c1, i|
        c2 = (i == shake.size -1 ) ? shake[0] : shake[i + 1]
        c1, c2 = c2, c1 if c2 < c1
        # +++ metric penalties
        penalties[c1][c2] += 1 if utilities[i] = max
      end
      penalties
    end

    # do local search
    def local_search(current, cities, penalties, max_no_improv, modifier)
      cost(current, penalties, cities, modifier)
      count = 0
      begin
        candidate = {:vector => stochastic_two_opt(current[:vector])}
        cost(candidate, penalties, cities, modifier)
        count = (candidate[:aug_cost] < current[:aug_cost]) ? 0 : count + 1
        current = candidate if candidate[:aug_cost] < current[:aug_cost]
      end until count >= max_no_improv
      current
    end

    # do search
    def search(max_iterations, cities, max_no_improv, modifier)
      current = {:vector => random_permuation(cities)}
      best = nil
      penalties = Array.new(cities.size){Array.new(cities.size, 0)}
      max_iterations.times do |iter|
        current = local_search(current, cities, penalties, max_no_improv, modifier)
        utilities = feature_utilities(penalties, cities, current[:vector])
        update_penalties!(penalties, cities, current[:vector], utilities)
        best = current if best.nil? or best[:cost] < curren[:cost]
        puts " > iter #{(iter + 1)}, best = #{best[:cost]}, aug = #{best[:aug_cost]}"
      end
      best
    end
  end
end
