import re
import os

def process_repo(path, methods_to_cache):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the class definition
    class_match = re.search(r'class \w+ \{', content)
    if not class_match: return
    
    inject_pos = class_match.end()
    
    # Check if cache already injected
    if "_last" in content and "_cached" in content:
        print(f"Skipping {path}, probably already has cache.")
        # Actually might not have it for all.
        pass

    cache_vars = ""
    for method, rettype in methods_to_cache:
        cache_name = f"_cached{method}"
        last_fetch = f"_last{method}FetchTime"
        cache_vars += f"\n  {rettype}? {cache_name};\n  DateTime? {last_fetch};\n"

    # Insert cache vars
    if "_cached" not in content[:inject_pos+50]:
        content = content[:inject_pos] + cache_vars + content[inject_pos:]

    # Now replace the methods
    for method, rettype in methods_to_cache:
        cache_name = f"_cached{method}"
        last_fetch = f"_last{method}FetchTime"
        
        # Regex to find: Future<rettype> method() async { ... }
        # Will replace it with cached version.
        pattern = r"(Future<" + re.escape(rettype) + r"> " + re.escape(method) + r"\([^)]*\)) async \{"
        
        def repl(m):
            sig = m.group(1)
            # if already has forceRefresh skip
            if "forceRefresh" in sig: return m.group(0)
            
            sig_with_param = sig.replace("()", "({bool forceRefresh = false})")
            if "()" not in sig:
                sig_with_param = sig.replace(")", ", bool forceRefresh = false)")
                
            return f"""{sig_with_param} async {{
    final now = DateTime.now();
    if (!forceRefresh && {cache_name} != null && {last_fetch} != null && now.difference({last_fetch}!).inMinutes < 15) {{
      return {cache_name}!;
    }}"""
            
        content = re.sub(pattern, repl, content)
        
        # Now find the first `return await ...;` inside this method and cache it.
        # This is harder to do safely via regex. Let's do it by replacing the try block if it's identical.
        # Actually, let's just find `return await ___ApiService.___();`
        
        api_call = re.search(r"(return await [^;]+;)", content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("done")
