# prof_parser_en.py
import pstats
import sys
import os
from pathlib import Path

def parse_profile_file(prof_file_path, top_n=20):
   """
   Parses .prof file and shows top bottlenecks
   """
   if not os.path.exists(prof_file_path):
       print(f"ERROR: File not found: {prof_file_path}")
       return
   
   try:
       stats = pstats.Stats(prof_file_path)
       
       print("=" * 80)
       print(f"PROFILE ANALYSIS: {Path(prof_file_path).name}")
       print("=" * 80)
       
       # 1. Top functions by cumulative time
       print("\nTOP FUNCTIONS BY CUMULATIVE TIME (including subcalls):")
       print("-" * 80)
       stats.sort_stats('cumulative')
       stats.print_stats(top_n)
       
       # 2. Top functions by total time
       print("\nTOP FUNCTIONS BY TOTAL TIME (excluding subcalls):")
       print("-" * 80)
       stats.sort_stats('tottime')
       stats.print_stats(top_n)
       
       # 3. Most called functions
       print("\nMOST FREQUENTLY CALLED FUNCTIONS:")
       print("-" * 80)
       stats.sort_stats('ncalls')
       stats.print_stats(top_n)
       
       # 4. Optimization recommendations
       print("\n" + "=" * 80)
       print("OPTIMIZATION RECOMMENDATIONS:")
       print("=" * 80)
       
       # Analyze data for recommendations
       stats.sort_stats('tottime')
       
       recommendations = analyze_bottlenecks_fixed(stats)
       for i, rec in enumerate(recommendations[:10], 1):
           print(f"{i}. {rec}")
           
   except Exception as e:
       print(f"ERROR processing file: {e}")

def analyze_bottlenecks_fixed(stats):
   """
   Analyzes profile and provides optimization recommendations
   """
   recommendations = []
   
   # Get statistics through proper interface
   stats.sort_stats('tottime')
   
   # Get top functions by redirecting print_stats to string
   import io
   from contextlib import redirect_stdout
   
   f = io.StringIO()
   with redirect_stdout(f):
       stats.print_stats(20)
   
   output = f.getvalue()
   lines = output.split('\n')
   
   # Parse result lines
   parsing_data = False
   for line in lines:
       if 'ncalls' in line and 'tottime' in line:
           parsing_data = True
           continue
       
       if parsing_data and line.strip():
           parts = line.split()
           if len(parts) >= 6:
               try:
                   ncalls = int(parts[0].split('/')[0]) if '/' in parts[0] else int(parts[0])
                   tottime = float(parts[1])
                   func_info = ' '.join(parts[5:])  # Function information
                   
                   if tottime < 0.01:  # Ignore functions with low time
                       continue
                   
                   # Analyze by patterns
                   if 'sleep' in func_info.lower():
                       recommendations.append(
                           f"I/O BLOCKING: {func_info} "
                           f"({tottime:.3f}s) - consider async programming"
                       )
                   elif 'memory_heavy_function' in func_info:
                       recommendations.append(
                           f"MEMORY INTENSIVE: {func_info} "
                           f"({tottime:.3f}s) - optimize memory usage"
                       )
                   elif 'cpu_intensive_task' in func_info:
                       recommendations.append(
                           f"CPU INTENSIVE: {func_info} "
                           f"({tottime:.3f}s) - consider NumPy or multiprocessing"
                       )
                   elif 'recursive_fibonacci' in func_info:
                       recommendations.append(
                           f"RECURSION: {func_info} "
                           f"({ncalls} calls, {tottime:.3f}s) - add memoization"
                       )
                   elif ncalls > 100000:
                       recommendations.append(
                           f"FREQUENT CALLS: {func_info} "
                           f"({ncalls} calls, {tottime:.3f}s) - optimize algorithm"
                       )
                   elif 'math.sin' in func_info or 'math.sqrt' in func_info:
                       recommendations.append(
                           f"MATH OPERATIONS: {func_info} "
                           f"({ncalls} calls, {tottime:.3f}s) - use NumPy for vectorization"
                       )
                   elif tottime > 0.1:
                       recommendations.append(
                           f"SLOW FUNCTION: {func_info} "
                           f"({tottime:.3f}s) - needs detailed analysis"
                       )
                       
               except (ValueError, IndexError):
                   continue
   
   return recommendations

def analyze_your_profile():
   """
   Detailed analysis for your specific profile
   """
   print("\n" + "DETAILED PROFILE ANALYSIS:")
   print("=" * 80)
   
   print("IDENTIFIED ISSUES:")
   print()
   print("1. CRITICAL: memory_heavy_function - 2.307s (67% of total time)")
   print("   - Creating large lists in memory")
   print("   - SOLUTION: Use generators or numpy arrays")
   print()
   
   print("2. MODERATE: cpu_intensive_task - 0.364s (11% of total time)")
   print("   - math.sin + math.sqrt called 1,000,000 times")  
   print("   - SOLUTION: Vectorization with NumPy")
   print()
   
   print("3. MODERATE: time.sleep - 0.301s (9% of total time)")
   print("   - Blocking I/O operations")
   print("   - SOLUTION: Asynchronous programming")
   print()
   
   print("4. MINOR: recursive_fibonacci - 0.053s")
   print("   - 242,785 recursive calls")
   print("   - SOLUTION: Memoization or iterative approach")
   
   print("\nOPTIMIZATION PLAN (by priority):")
   print("=" * 80)
   print("1. MEMORY: Replace lists with numpy arrays in memory_heavy_function")
   print("2. CPU: Use np.sin(), np.sqrt() instead of loops")  
   print("3. I/O: Replace time.sleep with asyncio.sleep")
   print("4. ALGORITHM: Add @lru_cache to fibonacci")
   
   print("\nEXPECTED RESULT: ~80% speedup (from 3.4s to ~0.7s)")

def generate_optimization_code():
   """
   Generates optimized code examples
   """
   print("\n" + "OPTIMIZED CODE EXAMPLES:")
   print("=" * 80)
   
   print("""
# BEFORE: Slow memory function
def memory_heavy_function():
   big_list = [random.random() for _ in range(100000)]
   another_list = [x * 2 for x in big_list] 
   combined = big_list + another_list
   return len(combined)

# AFTER: Fast function with NumPy  
import numpy as np
def memory_heavy_function_fast():
   big_array = np.random.random(100000)
   another_array = big_array * 2
   # Don't create copy, work with view
   return len(big_array) + len(another_array)

# BEFORE: Slow math calculations
def cpu_intensive_task():
   result = 0
   for i in range(1000000):
       result += math.sqrt(i) * math.sin(i)
   return result

# AFTER: Vectorized calculations
def cpu_intensive_task_fast():
   i = np.arange(1000000)
   result = np.sum(np.sqrt(i) * np.sin(i))
   return result

# BEFORE: Recursive fibonacci
def recursive_fibonacci(n):
   if n <= 1: return n
   return recursive_fibonacci(n-1) + recursive_fibonacci(n-2)

# AFTER: With memoization
from functools import lru_cache

@lru_cache(maxsize=None)
def fibonacci_fast(n):
   if n <= 1: return n
   return fibonacci_fast(n-1) + fibonacci_fast(n-2)
""")

def quick_analysis(prof_file):
   """
   Quick analysis for immediate insights
   """
   stats = pstats.Stats(prof_file)
   print(f"QUICK ANALYSIS: {prof_file}")
   print("-" * 50)
   
   stats.sort_stats('tottime')
   stats.print_stats(10)
   
   print("\nMAIN BOTTLENECKS:")
   
   import io
   from contextlib import redirect_stdout
   
   f = io.StringIO()
   with redirect_stdout(f):
       stats.print_stats(5)
   
   output = f.getvalue()
   lines = output.split('\n')
   
   parsing_data = False
   count = 0
   for line in lines:
       if 'ncalls' in line and 'tottime' in line:
           parsing_data = True
           continue
       
       if parsing_data and line.strip() and count < 3:
           parts = line.split()
           if len(parts) >= 6:
               try:
                   tottime = float(parts[1])
                   func_info = ' '.join(parts[5:])
                   print(f"• {func_info} - {tottime:.3f}s")
                   count += 1
               except (ValueError, IndexError):
                   continue

def main():
   if len(sys.argv) < 2:
       print("Usage:")
       print("  python prof_parser_en.py <file.prof> [top_n]")
       print("  python prof_parser_en.py <file.prof> quick")
       print("")
       print("Examples:")
       print("  python prof_parser_en.py profile.prof")
       print("  python prof_parser_en.py profile.prof 30")
       print("  python prof_parser_en.py profile.prof quick")
       return
   
   prof_file = sys.argv[1]
   
   if len(sys.argv) > 2 and sys.argv[2] == 'quick':
       quick_analysis(prof_file)
       return
   
   top_n = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 20
   
   parse_profile_file(prof_file, top_n)
   analyze_your_profile()
   
   if input("\nShow optimized code examples? (y/n): ").lower() == 'y':
       generate_optimization_code()

if __name__ == "__main__":
   main()
