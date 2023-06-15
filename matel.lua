local function BitArray(blen)
    local bits = {}
    local bitslen = blen
    for i = 1, bitslen, 1 do
        bits[i] = false
    end
    local ret =  {
        ToInt = function()
            local maxnum = 1
            local intvalue = 0
            for i = 1, bitslen, 1 do
                if bits[i] then
                    intvalue = intvalue + maxnum
                end
                maxnum = maxnum * 2
            end
            return intvalue
        end,

        Set = function (index,value)
            if index >= 0 and index < bitslen and type(value) == "boolean" then
                bits[index + 1] = value
            end
        end,
        SetArray = function (index,arr)
            local maxindex = math.min(bitslen,index + #arr)
            local i2 = 1
            for i = index + 1, maxindex, 1 do
                bits[i] = arr[i2]
                i2 = i2 + 1
            end
        end,
        Get = function (index)
            if index >= 0 and index < bitslen then
                return bits[index + 1]
            end
            return nil
        end,
        GetArray = function (index,len)
            local arr = {}
            local maxindex = math.min(bitslen,index + len)
            local i2 = 1
            for i = index + 1, maxindex, 1 do
                arr[i] = bits[i2]
                i2 = i2 + 1
            end
            return arr
        end,
        ToString = function ()
            local str = ""
            local buffstr = ''
            for i = 1, bitslen, 1 do
                if bits[i] then buffstr = '1' else buffstr = '0' end
                str = buffstr .. str
            end
            return str
        end,
    }
    ret.ToHexStr = function ()
        local numv = ret.ToInt()
        return string.format("%x",numv)
    end
    return ret
end
local function IntToBitArray(value, len)
    local bitarray = BitArray(len)
    local i2 = 0
    local vtest = 0x1
    for i = 1, len, 1 do
        local currentbit = (value & vtest) == vtest

        bitarray.Set(i2, currentbit)
        i2 = i2 + 1
        vtest = vtest << 1

    end
    return bitarray
end
local RegisterFlag = {
    R0 = 0,
    R1 = 1,
    R2 = 2,
    R3 = 3,
    R4 = 4,
    R5 = 5,
    R6 = 6,
    R7 = 7
}

local ConditionType = {
    G = 0,
    E = 1,
    L = 2
}
local RegisterSpecialFlag = {
    Carry = 0,
    Remainder = 1,
    GF = 2,
    EF = 3,
    LF = 4,
    Borrow = 5
}
local Assembly = {
    _add = function (with_imm,with_carry,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,false,false,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,with_carry)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _sub = function (with_imm,with_borrow,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,true,false,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,with_borrow)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _mul = function (with_imm,with_carry,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,true,false,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,with_carry)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _div = function (with_imm,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,false,true,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,false)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,

    _and = function (with_imm,not_result,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,false,true,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,not_result)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _xor = function (with_imm,not_result,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,true,true,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,not_result)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,

    _not = function (with_imm,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,false,true,false,false})
        bp.Set(0,with_imm)
        bp.Set(1,false)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _or = function (with_imm,not_result,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,false,false,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,not_result)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _cmp = function (with_imm,not_flags,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,false,false,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,not_flags)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _sl = function (with_imm,direction,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,true,false,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,direction)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _sr = function (with_imm,direction,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,true,false,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,direction)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,
    _inc_dec = function (with_imm,isdec,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{false,false,true,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,isdec)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,

    _neg = function (with_imm,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if with_imm then
            op2_size = 6
        end
        bp.SetArray(11,{true,false,true,true,false})
        bp.Set(0,with_imm)
        bp.Set(1,false)
        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,

    _mov = function (movtype,op1,op2)
        local bp = BitArray(16)
        local op2_size = 3
        if movtype == 1 then
            op2_size = 6
        end
        bp.SetArray(11,{false,true,true,true,false})

        local movtype_b = IntToBitArray(movtype,2)
        local movtype_a = movtype_b.GetArray(0,2)
        bp.SetArray(0,movtype_a)

        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,op2_size)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,op2_size)
        bp.SetArray(2,r1a)
        bp.SetArray(5,r2a)

        return bp
    end,

    _cmov = function (isregisterspecial,conditiontype,notcondition,op1,op2)
        local bp = BitArray(16)
        bp.SetArray(11,{true,true,true,true,false})

        bp.Set(0,isregisterspecial)
        
        local conditiontype_b = IntToBitArray(conditiontype,2)
        local conditiontype_a = conditiontype_b.GetArray(0,2)
        bp.SetArray(1,conditiontype_a)

        bp.Set(3,notcondition)

        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,3)
        local r1a = op1_b.GetArray(0,3)
        local r2a = op2_b.GetArray(0,3)
        bp.SetArray(4,r1a)
        bp.SetArray(7,r2a)

        return bp
    end,
    _cmov2 = function (flagtype,op1,imm6)
        local bp = BitArray(16)
        bp.SetArray(11,{false,false,false,false,true})
        
        local conditiontype_b = IntToBitArray(flagtype,2)
        local conditiontype_a = conditiontype_b.GetArray(0,2)
        bp.SetArray(0,conditiontype_a)

        local op1_b = IntToBitArray(op1,3)
        local imm6_b = IntToBitArray(imm6,3)
        local r1a = op1_b.GetArray(0,3)
        local imm6_a = imm6_b.GetArray(0,6)
        bp.SetArray(2,r1a)
        bp.SetArray(5,imm6_a)

        return bp
    end,
    _cmov3 = function (flagtype,op1,imm6)
        local bp = BitArray(16)
        bp.SetArray(11,{true,false,false,false,true})
        
        local conditiontype_b = IntToBitArray(flagtype,2)
        local conditiontype_a = conditiontype_b.GetArray(0,2)
        bp.SetArray(0,conditiontype_a)

        local op1_b = IntToBitArray(op1,3)
        local imm6_b = IntToBitArray(imm6,3)
        local r1a = op1_b.GetArray(0,3)
        local imm6_a = imm6_b.GetArray(0,6)
        bp.SetArray(2,r1a)
        bp.SetArray(5,imm6_a)

        return bp
    end,

    _load = function (isimm,op1,op2)
        local bp = BitArray(16)
        local lenop2 = 3
        if isimm then
            lenop2 = 6
        end
        bp.SetArray(11,{false,true,false,false,true})
        
        bp.Set(0,isimm)
        bp.Set(1,false)

        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,lenop2)
        local r1a = op1_b.GetArray(0,3)
        local op2_a = op2_b.GetArray(0,lenop2)
        bp.SetArray(2,r1a)
        bp.SetArray(5,op2_a)

        return bp
    end,
    _store = function (isimm,op1,op2)
        local bp = BitArray(16)
        local lenop2 = 3
        if isimm then
            lenop2 = 6
        end
        bp.SetArray(11,{true,true,false,false,true})
        
        bp.Set(0,isimm)
        bp.Set(1,false)

        local op1_b = IntToBitArray(op1,3)
        local op2_b = IntToBitArray(op2,lenop2)
        local r1a = op1_b.GetArray(0,3)
        local op2_a = op2_b.GetArray(0,lenop2)
        bp.SetArray(2,r1a)
        bp.SetArray(5,op2_a)

        return bp
    end,
    _jmp = function (isimm,conditiontype,notcondition,op1)
        local bp = BitArray(16)
        local lenop1 = 3
        if isimm then
            lenop1 = 6
        end
        
        bp.SetArray(11,{false,false,true,false,true})
        
        bp.Set(0,isimm)
        local conditiontype_b = IntToBitArray(conditiontype,2)
        local conditiontype_a = conditiontype_b.GetArray(0,2)
        bp.SetArray(1,conditiontype_a)
        bp.Set(3,notcondition)

        local op1_b = IntToBitArray(op1,lenop1)
        local op1_a = op1_b.GetArray(0,lenop1)
        bp.SetArray(5,op1_a)

        return bp
    end,
}

local Matel = function (filepath)
    local file = io.open(filepath,"wb")
    if file == nil then
        return nil
    end
    file:write("v2.0 raw\n")
    
    local function WriteHex(bp)
        file:write(bp.ToHexStr() .. " ")
    end
    
    return {
        add = function (reg1,reg2)
            local v = Assembly._add(false,false,reg1,reg2)
            WriteHex(v)
        end,
        addi = function (reg1,imm6)
            local v = Assembly._add(true,false,reg1,imm6)
            WriteHex(v)
        end,
        addc = function (reg1,reg2)
            local v = Assembly._add(false,true,reg1,reg2)
            WriteHex(v)
        end,
        addic = function (reg1,imm6)
            local v = Assembly._add(true,true,reg1,imm6)
            WriteHex(v)
        end,
        sub = function (reg1,reg2)
            local v = Assembly._sub(false,false,reg1,reg2)
            WriteHex(v)
        end,
        subi = function (reg1,imm6)
            local v = Assembly._sub(true,false,reg1,imm6)
            WriteHex(v)
        end,
        subb = function (reg1,reg2)
            local v = Assembly._sub(false,true,reg1,reg2)
            WriteHex(v)
        end,
        subib = function (reg1,imm6)
            local v = Assembly._sub(true,true,reg1,imm6)
            WriteHex(v)
        end,
        mul = function (reg1,reg2)
            local v = Assembly._mul(false,false,reg1,reg2)
            WriteHex(v)
        end,
        muli = function (reg1,imm6)
            local v = Assembly._mul(true,false,reg1,imm6)
            WriteHex(v)
        end,
        mulc = function (reg1,reg2)
            local v = Assembly._mul(false,true,reg1,reg2)
            WriteHex(v)
        end,
        mulic = function (reg1,imm6)
            local v = Assembly._mul(true,true,reg1,imm6)
            WriteHex(v)
        end,
        div = function (reg1,reg2)
            local v = Assembly._div(false,reg1,reg2)
            WriteHex(v)
        end,
        divi = function (reg1,imm6)
            local v = Assembly._div(true,reg1,imm6)
            WriteHex(v)
        end,

        ["and"] = function (reg1,reg2)
            local v = Assembly._and(false,false,reg1,reg2)
            WriteHex(v)
        end,
        andi = function (reg1,imm6)
            local v = Assembly._and(true,false,reg1,imm6)
            WriteHex(v)
        end,
        nand = function (reg1,reg2)
            local v = Assembly._and(false,true,reg1,reg2)
            WriteHex(v)
        end,
        nandi = function (reg1,imm6)
            local v = Assembly._and(true,true,reg1,imm6)
            WriteHex(v)
        end,
        xor = function (reg1,reg2)
            local v = Assembly._xor(false,false,reg1,reg2)
            WriteHex(v)
        end,
        xori = function (reg1,imm6)
            local v = Assembly._xor(true,false,reg1,imm6)
            WriteHex(v)
        end,
        nxor = function (reg1,reg2)
            local v = Assembly._xor(false,true,reg1,reg2)
            WriteHex(v)
        end,
        nxori = function (reg1,imm6)
            local v = Assembly._xor(true,true,reg1,imm6)
            WriteHex(v)
        end,
        ["not"] = function (reg1,reg2)
            local v = Assembly._not(false,reg1,reg2)
            WriteHex(v)
        end,
        noti = function (reg1,imm6)
            local v = Assembly._not(true,reg1,imm6)
            WriteHex(v)
        end,
        ["or"] = function (reg1,reg2)
            local v = Assembly._or(false,false,reg1,reg2)
            WriteHex(v)
        end,
        ori = function (reg1,imm6)
            local v = Assembly._or(true,false,reg1,imm6)
            WriteHex(v)
        end,
        nor = function (reg1,reg2)
            local v = Assembly._or(false,true,reg1,reg2)
            WriteHex(v)
        end,
        nori = function (reg1,imm6)
            local v = Assembly._or(true,true,reg1,imm6)
            WriteHex(v)
        end,
        cmp = function (reg1,reg2)
            local v = Assembly._cmp(false,false,reg1,reg2)
            WriteHex(v)
        end,
        cmpi = function (reg1,imm6)
            local v = Assembly._cmp(true,false,reg1,imm6)
            WriteHex(v)
        end,
        ncmp = function (reg1,reg2)
            local v = Assembly._cmp(false,true,reg1,reg2)
            WriteHex(v)
        end,
        ncmpi = function (reg1,imm6)
            local v = Assembly._cmp(true,true,reg1,imm6)
            WriteHex(v)
        end,
        sll = function (reg1,reg2)
            local v = Assembly._sl(false,false,reg1,reg2)
            WriteHex(v)
        end,
        slli = function (reg1,imm6)
            local v = Assembly._sl(true,false,reg1,imm6)
            WriteHex(v)
        end,
        slr = function (reg1,reg2)
            local v = Assembly._sl(false,true,reg1,reg2)
            WriteHex(v)
        end,
        slri = function (reg1,imm6)
            local v = Assembly._sl(true,true,reg1,imm6)
            WriteHex(v)
        end,
        srl = function (reg1,reg2)
            local v = Assembly._sr(false,false,reg1,reg2)
            WriteHex(v)
        end,
        srli = function (reg1,imm6)
            local v = Assembly._sr(true,false,reg1,imm6)
            WriteHex(v)
        end,
        srr = function (reg1,reg2)
            local v = Assembly._sr(false,true,reg1,reg2)
            WriteHex(v)
        end,
        srri = function (reg1,imm6)
            local v = Assembly._sr(true,true,reg1,imm6)
            WriteHex(v)
        end,
        inc = function (reg1,reg2)
            local v = Assembly._inc_dec(false,false,reg1,reg2)
            WriteHex(v)
        end,
        inci = function (reg1,imm6)
            local v = Assembly._inc_dec(true,false,reg1,imm6)
            WriteHex(v)
        end,
        dec = function (reg1,reg2)
            local v = Assembly._inc_dec(false,true,reg1,reg2)
            WriteHex(v)
        end,
        deci = function (reg1,imm6)
            local v = Assembly._inc_dec(true,true,reg1,imm6)
            WriteHex(v)
        end,
        neg = function (reg1,reg2)
            local v = Assembly._neg(false,reg1,reg2)
            WriteHex(v)
        end,
        negi = function (reg1,imm6)
            local v = Assembly._neg(true,reg1,imm6)
            WriteHex(v)
        end,
        mov = function (reg1,reg2)
            local v = Assembly._mov(0,reg1,reg2)
            WriteHex(v)
        end,
        movi = function (reg1,imm6)
            local v = Assembly._mov(1,reg1,imm6)
            WriteHex(v)
        end,
        movf = function (reg1,imm6)
            local v = Assembly._mov(2,reg1,imm6)
            WriteHex(v)
        end,
        cmov = function (conditiontype,reg1,reg2)
            local v = Assembly._cmov(false,conditiontype,false,reg1,reg2)
            WriteHex(v)
        end,
        cmovf = function (conditiontype,reg1,reg2)
            local v = Assembly._cmov(true,conditiontype,false,reg1,reg2)
            WriteHex(v)
        end,
        cmovn = function (conditiontype,reg1,reg2)
            local v = Assembly._cmov(false,conditiontype,true,reg1,reg2)
            WriteHex(v)
        end,
        cmovfn = function (conditiontype,reg1,reg2)
            local v = Assembly._cmov(true,conditiontype,true,reg1,reg2)
            WriteHex(v)
        end,
        cmovi = function (conditiontype,reg1,imm6)
            local v = Assembly._cmov2(conditiontype,reg1,imm6)
            WriteHex(v)
        end,
        cmovin = function (conditiontype,reg1,imm6)
            local v = Assembly._cmov3(conditiontype,reg1,imm6)
            WriteHex(v)
        end,
        load = function (reg1,reg2)
            local v = Assembly._load(false,reg1,reg2)
            WriteHex(v)
        end,
        loadai = function (reg1,imm6)
            local v = Assembly._load(true,reg1,imm6)
            WriteHex(v)
        end,
        store = function (reg1,reg2)
            local v = Assembly._store(false,reg1,reg2)
            WriteHex(v)
        end,
        storeai = function (reg1,imm6)
            local v = Assembly._store(true,reg1,imm6)
            WriteHex(v)
        end,

        jmp = function (conditiontype,reg1)
            local v = Assembly._jmp(false,conditiontype,false,reg1)
            WriteHex(v)
        end,
        jmpi = function (conditiontype,imm6)
            local v = Assembly._jmp(true,conditiontype,false,imm6)
            WriteHex(v)
        end,
        jmpn = function (conditiontype,reg1)
            local v = Assembly._jmp(false,conditiontype,true,reg1)
            WriteHex(v)
        end,
        jmpin = function (conditiontype,imm6)
            local v = Assembly._jmp(true,conditiontype,true,imm6)
            WriteHex(v)
        end,
    }
    
end




return { new = Matel,RegisterFlag = RegisterFlag,ConditionType = ConditionType,RegisterFlagType = RegisterSpecialFlag}