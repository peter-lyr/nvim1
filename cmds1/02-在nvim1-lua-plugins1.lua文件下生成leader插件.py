for i in range(97, 97 + 26):
    i = chr(i)
    if i in ["j", "k"]:
        continue
    a = f"""
  -- -- leader_{i}
  -- {{
  --   name = 'leader_{i}',
  --   dir = Nvim1Leader .. 'leader_{i}',
  --   keys = {{
  --     {{ '<leader>{i}', desc = 'leader_{i}', }},
  --   }},
  -- }},
    """
    print("  " + a.strip() + "\n")
