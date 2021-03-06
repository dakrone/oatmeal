#!/usr/bin/env ruby
#
# Complexity code from: http://eigenclass.org/hiki/Lexical+complexity+in+Ruby

require 'matrix'
require 'find'
require 'fileutils'
require 'yaml'
require 'activerecord'
require 'beanstalk-client'
require 'thread'

require 'gitobjects'

class Object
  _stationary_distribution_cache = {}
  max_iterations = 10

  define_method(:stationary_distribution) do |t_matrix, *rest|
    if _stationary_distribution_cache.has_key?(t_matrix)
      _stationary_distribution_cache[t_matrix]
    else
      threshold = rest[0] ? rest[0] : 0.001
      2.times{ t_matrix = t_matrix * t_matrix }
      iterations = 0
      loop do
        t_matrix = t_matrix * t_matrix
        # should verify that they are all close, but the following weaker
        # test will do 
        d1 = (t_matrix.row(0) - t_matrix.row(t_matrix.row_size - 1)).to_a.inject{|s,x| s + x.abs}
        d2 = (t_matrix.row(0) - t_matrix.row(t_matrix.row_size/2)).to_a.inject{|s,x| s + x.abs}
        break if d1 < threshold && d2 < threshold || iterations > max_iterations
        iterations += 1
      end
      return nil if iterations >= max_iterations
      _stationary_distribution_cache[t_matrix] = t_matrix.row(0).to_a
    end
  end
end

module Oatmeal

  class Complexid
    LOG2 = Math.log(2)

    attr_reader :statistics

    # queue is a string containing a location of a beanstalk server
    def initialize(dbenv, queue)
      @dbenv = ActiveRecord::Base::establish_connection(dbenv)
      @queue = Beanstalk::Pool.new([queue])

      @statistics = {}
      @running = false

      # Thread for running
      @t = nil
    end


    def start
      raise "ComplexiD is already running!" if @running

      @running = true
      @t = Thread.new { 
        trap "SIGTERM", Proc.new { puts "Dying!" }
        STDERR.puts "ComplexiD Started."
        while @running
          begin
            job = @queue.reserve(3)
          rescue Exception => e
            next
          end

          STDERR.puts "processing [#{job.body}]..."
          STDERR.flush
          process_git_repo(job.body) unless job.body.nil?
          
          job.delete
        end

      }
    end

    def running?
      @running
    end

    def stop
      STDERR.puts "Shutting down..."
      @running = false
      Thread.kill(@t)
      STDERR.puts "ComplexiD Halted."
    end


    def git_checkout_url(url)
      repo = Repository.new(url)
      return nil unless repo.clone
      repo
    end

    def process_directory(dir)
      $stdout.sync = true
      begin
        Dir.chdir(dir) do
          Find.find(".") do |file|
            next unless /\.rb$/ =~ file
            groupname = File.dirname(file).split(%r{/})[1]
            groupname = File.basename(file)[/[^.]+/] if groupname.nil?

            t_matrix, freqs, indices, tokens = transition_matrix(file)
            if t_matrix
              h_rate = entropy_rate(t_matrix)
              if h_rate
                mu = stationary_distribution(t_matrix)
              else
                h_rate = freqs.inject([0,0]) do |(s,idx), p|
                [s + p * H(t_matrix.row(idx)), idx + 1]
                end.first
                mu = freqs
              end

              h_iid = H(mu)
              h_eq1 = mu.inject([0,0]) do |(s,idx), p|
              non_zero = t_matrix.row(idx).to_a.select{|x| x > 0}.size
              non_zero = [1, non_zero].max
              [s + p * Math.log(non_zero) / LOG2, idx + 1]
              end.first
              h_eq2 = Math.log(t_matrix.row_size) / LOG2

              (@statistics[groupname] ||= []) << [file, h_rate, h_eq1, h_iid, h_eq2, tokens]
              #p [file, h_rate, h_eq1, h_iid, h_eq2, tokens]
              # [file, 
              #  h_rate  either the entropy rate of the markov chain if there is
              #          a stationary distribution or the weighted sum of the
              #          entropies for each row in the transition matrix, based on
              #          the observed frequencies for the prev token type
              #  h_eq1   entropy if all possible (as observed by an instance of the
              #          process) choices given the prev token are equidistributed
              #  h_iid   we ignore the markovian process and consider this as a
              #          stochastic process of indep. identically distributed
              #          random variables (so all tokens are considered independent)
              #  h_eq2   entropy per token if we consider them all equally probable
              #  tokens  number of tokens
              # ]
            end
          end
        end
      end
      @statistics
    end

    def push_stats(stats=@statistics)
      return nil if @statistics.empty?

      y stats
      # TODO: implement
    end

    # clone, calculate and push to db
    def process_git_repo(url)

      repo = git_checkout_url(url)
      raise "Unable to check out git repo." if repo.nil?

      process_directory(repo.project_dir)

      push_stats
    end


    private
    def transition_matrix(filename)
      indices = Hash.new{|h,k| h[k] = indices.size}
      probs = []
      last_tok = nil
      ntokens = 0
      freqs = []
      IO.popen("ruby -y -c #{filename} 2>&1") do |f|
        f.each do |line|
          if md = /^Reading a token: Next token is token (\S+)/.match(line)
            tok = md[1]
            ntokens += 1
            freqs[indices[tok]] ||= 0
            freqs[indices[tok]] += 1
            if last_tok
              probs[indices[last_tok]] ||= []
              probs[indices[last_tok]][indices[tok]] ||= 0
              probs[indices[last_tok]][indices[tok]] += 1
            end
            last_tok = tok
          end
        end
      end
      if ntokens == 0
        return [nil, nil, nil, 0]
      end
      probs.map! do |row|
        sum = row.inject(0){|s,x| s + (x || 0)}
        row.map{|x| 1.0 * (x || 0) / sum }
      end

      freqs = freqs.map{|p| 1.0 * p / ntokens }
      cols = [probs.size, probs.map{|x| x.size}.max].max
      probs << [0] * cols if probs.size < cols
      [Matrix.rows(probs.map{|row| row + [0] * (cols - row.size)}), freqs, indices, ntokens]
    end

    def H(probs)
      probs.to_a.inject(0) do |s,x|
        if x < 1e-6 # for continuity
          s
        else
          s - 1.0 * x * Math.log(x) / LOG2
        end
      end
    end

    def entropy_rate(t_matrix)
      mu = stationary_distribution(t_matrix)
      return nil if mu.nil?
      ret = 0
      mu.each_with_index do |p, row|
        ret += p * H(t_matrix.row(row))
      end
      ret
    end


  end
end

