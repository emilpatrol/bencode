module bencode.parser;

import bencode.builder;
import std.conv : to;
import std.ascii;
import std.string;

class BencodeParserException : Exception{
    this(string s){
        super(s);
    }
} 

class BencodeParser{

    this(BencodeBuilder b){
        _builder = b;
    }

    void construct(in string data){
        for(size_t i = 0; i < data.length;){
            size_t tmp;
            switch(data[i]){
                
                case 'i':
                    i += buildInteger(data[i .. $]);
                break;
                
                case '0': .. case '9':
                    i += buildString(data[i .. $]);
                break;
               
                case 'l':
                    i += buildList();
                break;
                
                case 'd':
                    i += buildDict();
                break;
                
                case 'e':
                    i += buildEnd();
                break;
                
                default:
                    throw new BencodeParserException(to!string(i));
            }
        }    
    }
    
    private:
        BencodeBuilder _builder;
    
    size_t buildInteger(in string data){
        
        size_t lenInteger(in string data){
            size_t p = verifyLenExp('e', data);
            verifyStringIsDigits(data[1 .. p]);
            return ++p;
        }
        
        size_t tmp = lenInteger(data);
        _builder.BuildInteger(data[0 .. tmp]);
        return tmp;        
    }

    size_t buildString(in string data){
        size_t p = verifyLenExp(':', data);
        verifyStringIsDigits(data[0 .. p]);
        size_t length = to!int(data[0 .. p]);
        length += p + 1;
        if(length > data.length){
            throw new BencodeParserException("Length = " ~ to!string(length) ~ " Data.Length = " ~ to!string(data.length));
        }
        _builder.BuildString(data[0 .. length]);
        return length;
    }

    size_t buildList(){
        _builder.BuildList();
        return 1;
    }

    size_t buildDict(){
        _builder.BuildDict();
        return 1;
    }

    size_t buildEnd(){
        _builder.BuildEnd();
        return 1;
    }

    static void verifyStringIsDigits(in string data){
        foreach(c; data){
            if(!isDigit(c)){
               throw new BencodeParserException(to!string(c)); 
            }
        }
    }
    
    static size_t verifyLenExp(char c, in string data){
        size_t p = data.indexOf(c); 
        if(p == -1){
            throw new BencodeParserException(c ~ " " ~ data[0 .. 10]);
        }
        return p;   
    }
    
}

unittest{
    import std.file;
    BencodeBuilder builder = new NodeBencodeBuilder();
    BencodeParser parser = new BencodeParser(builder); 
    string data = to!string(read("1.torrent"));
    parser.construct(data); 
}
