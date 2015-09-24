module bencode.builder;

import std.typecons;
import std.conv : to;
import std.string;
import std.algorithm.searching;
import std.digest.sha;
import bencode.node;
public import bencode.node : Node;

class BencodeFormatException : Exception {
    this(string msg){
        super(msg);
    }
}

class BencodeBuilder{
    void BuildInteger(in string data){};
    void BuildString(in string data){};
    void BuildList(){};
    void BuildDict(){};
    void BuildEnd(){};
}

class NodeBencodeBuilder : BencodeBuilder{
    
    Node getNode(){
        if(level.length != 0){
            throw new BencodeFormatException("Error of nesting");
        }
        return node;    
   } 
   
   override void BuildInteger(in string data){
        long i = getInteger(data);
        insert(new IntegerNode(i));
    }
    
    override void BuildString(in string data){
        string str = getString(data);
        insert(new StringNode(str));
    }

    override void BuildList(){
        insert(new ListNode());
    }

    override void BuildDict(){
        insert(new DictNode());
    }

    override void BuildEnd(){
        if(level.length == 0){
            throw new BencodeFormatException("Error of nesting");                           
        }
        level.length -= 1;
    }
    
    private:
 
        Tuple!(Node, "node", string, "key")[] level;
        Node node = null;
        
        long getInteger(in string data){
            return to!long(data[1.. $ -1]);
        } 

        string getString(in string data){
            size_t p = data.indexOf(':');
            return data[++p .. $];
        }

        void insert(Node nnode){
            if(!node){
                node = nnode;
            }
            else if(level){
                if(level[$ - 1].node.type == BencodeType.List){
                    level[$ -1].node ~= nnode;
                }
                else if(level[$ - 1].node.type == BencodeType.Dict){
                    if(level[$ - 1].key == string.init && nnode.type == BencodeType.String){
                        level[$ - 1].key = nnode.getString();
                    }
                    else if(level[$ - 1].key != string.init){
                        level[$ - 1].node[level[$ - 1].key] = nnode;
                        level[$ - 1].key = string.init;
                    }
                    else{
                        throw new BencodeFormatException("The key of dict, can be " ~ BencodeType.String.toString() ~ " but met " ~ nnode.type.toString());
                    }
                }
            }
            else{
                throw new BencodeFormatException("Error of nesting");
            }

            if(nnode.type == BencodeType.Dict || nnode.type == BencodeType.List){
                level ~= tuple!("node", "key")(nnode, string.init);
            }
        }
           
}

unittest{
    NodeBencodeBuilder builder = new NodeBencodeBuilder();
    builder.BuildDict();
    builder.BuildEnd();
    assert(builder.getNode().type == BencodeType.Dict);
    builder = new NodeBencodeBuilder();
    builder.BuildDict();
    builder.BuildString("3:qwe");
    builder.BuildInteger("i2e");
    builder.BuildEnd();
    Node n = builder.getNode();
    assert(n["qwe"].getInteger() == 2);
    builder = new NodeBencodeBuilder();
    builder.BuildInteger("i3e");
    try{
        builder.BuildInteger("i4e");
    }
    catch(BencodeFormatException e){
        assert(e.msg == "Error of nesting");
    }
    
    builder = new NodeBencodeBuilder();
    builder.BuildDict();
    builder.BuildString("1:1");
    builder.BuildList();
    builder.BuildInteger("i1e");
    builder.BuildInteger("i2e");
    builder.BuildEnd();
    builder.BuildString("1:2");
    builder.BuildInteger("i3e");
    builder.BuildEnd();
    try{
        builder.BuildEnd();
    }
    catch(BencodeFormatException e){
        assert(e.msg == "Error of nesting");
    } 

    builder = new NodeBencodeBuilder();
    builder.BuildDict();
    try{
        builder.getNode();
    }
    catch(BencodeFormatException e){
        assert(e.msg == "Error of nesting");
    }
    try{
        builder.BuildInteger("i1e");
    }
    catch(BencodeFormatException e){
        assert(e.msg == "The key of dict, can be " ~ BencodeType.String.toString() ~ " but met " ~ BencodeType.Integer.toString());  
    }           
}
