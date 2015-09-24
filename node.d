module bencode.node;

import std.conv : to;
import std.algorithm.sorting;

enum BencodeType {Integer, String, List, Dict};

string toString(E)(E value) if(is(E == enum)){
    foreach(s; __traits(allMembers, E))
        if(value == mixin ("E." ~ s)) return s;
    return null;
}

class NodeTypeException : Exception{
    this(string type, string type2){
        super("Object must be of type " ~ type ~" , but object of type " ~ type2 ~".");
    }    
}

class Node{

// Methods for IntegerNode 

    long getInteger(){ 
        exception("Integer");
        return 0;
    }

//Methods for StringNode
    
    string getString(){ 
        exception("String");
        return "";
    }

//Methods for ListNode

    void opOpAssign(string op)(Node node) if (op == "~"){ concat(node);};
    
    void concat(Node node){
        exception("List");
    }

    Node opIndex(size_t index){
        return null;
    }

    Node opSlice(size_t b1, size_t b2){
        return null;
    }

    int opApply(int delegate(Node n) dg){
        return 0;
    }

//Methods for DictNode

    Node opIndex(string key){
        return index(key);
    }
        
    protected Node index(string key){
        exception("Dict");
        return null;
    }

    Node opIndexAssign(Node n, string key){
        return indexAssign(n, key);
    }
        
    Node indexAssign(Node n, string key){
        exception("Dict");
        return null;
    }

    Node * opBinaryRight(string op)(string lhs) if(op == "in"){
        return binaryRight(lhs);
    }
        
    Node * binaryRight(string lhs){
        exception("Dict");
        return null;
    }

    int opApply(int delegate (string k, Node v) dg){
        return 0;
    }

    void remove(string key){
        exception("Dict");
    }


//Methods for All

    size_t length() const @property{
        return 0;
    }

    @property BencodeType type(){
        return bencodetype;
    }

    abstract string getBencode();
    
    size_t opDollar(size_t i)(){
        return Dollar();
    }

    size_t opDollar(){
        return Dollar();
    }

    protected size_t Dollar(){
        exception("List or Dict");
        return 0;
    } 

    private void exception(string ttype){
            throw new NodeTypeException(ttype, type.toString());
    }
    
    private BencodeType bencodetype;
}

class IntegerNode : Node{

    this(long i){
        this.i = i;
        bencodetype = BencodeType.Integer;
    }
    
    override long getInteger(){
        return i;
    }

    override string getBencode(){
        auto value = to!string(i);
        return "i" ~  value ~ "e";
    }

    private:
        long i;      
}    


class StringNode : Node{
    
    this(string str){
        this.str = str;
        bencodetype = BencodeType.String;
    }

    override string getString(){
        return str;
    }

    override string getBencode(){
        auto value = to!string(str.length);
        return value ~ ":" ~ str;
    }
    
    @property
    override size_t length() const{
        return str.length;
    }

   private:
        string str; 
}

class ListNode : Node{

    this(){
        p = list.ptr;
        bencodetype = BencodeType.List;
    }
    
    override void concat(Node node){
        list ~= node;
        p = list.ptr;
    }

    override Node opIndex(size_t index){
        return list[index];
    }

    override ListNode opSlice(size_t b1, size_t b2){
        list = list[b1 .. b2];
        return this;
    }

    @property
    override size_t length() const{
        return list.length;
    }

    override int opApply(int delegate(Node n) dg){
        auto result = 0;
        foreach(Node n; list){
            result = dg(n);
        }
        return result;    
    }

    override string getBencode(){
        string result = "l";
        foreach(Node n; list){
            result ~= n.getBencode();
        }
        result ~= "e";
        return result;
    }

    protected override size_t Dollar() const {
        return list.length;
    }

    private:
        Node[] list;
        Node * p;
}

class DictNode : Node{

    this(){
        bencodetype = BencodeType.Dict;
    }
    
    override Node index(string key){
        auto p = key in dict;
        return *p; 
    }

    override Node indexAssign(Node n, string key){
        dict[key] = n;
        return n;
    }

    override Node * binaryRight(string lhs){
        return lhs in dict;
    }

    override void remove(string key){
        dict.remove(key);
    }

    override string getBencode(){
        string[] keys = dict.keys;
        sort(keys);
        string result = "d";
        foreach(string s; keys){
            StringNode ns = new StringNode(s);
            result ~= ns.getBencode();
            result ~= dict[s].getBencode();
        }
        result ~= "e";
        return result;
    }

    @property
    override size_t length() const{
        return dict.length;
    }

    protected override size_t Dollar() const {
        return dict.length;
    }
        
    private:      
            Node[string] dict;
            string key = "";
            string tmpkey;
    

}

unittest{
    IntegerNode bi = new IntegerNode(2);
    assert(bi.getInteger() == 2);
    assert(bi.getBencode() == "i2e");
    Node n = bi;
    assert(n.getInteger() == 2);
    assert(n.getBencode() == "i2e");

    StringNode si = new StringNode("jello");
    assert(si.length == 5);
    assert(si.getString() == "jello");
    assert(si.getBencode() == "5:jello");
    n = si;
    assert(n.length == 5);
    assert(n.getString() == "jello");
    assert(n.getBencode() == "5:jello");

    ListNode li = new ListNode();
    li ~= bi;
    assert(li.length == 1);
    assert(li[0] is bi);
    li ~=si;
    assert(li.length == 2);
    li = li[0 .. $ - 1];
    assert(li.length == 1);
    assert(li[0] is bi);
    foreach(Node n; li){
        assert(n.type == BencodeType.Integer || n.type == BencodeType.String);
    }
    assert(li.getBencode() == "li2ee");
    n = li;
    assert(n.length == 1);
    assert(n[0] is bi);
    li ~= si;
    assert(n.length == 2);
    n = n[0 .. $ - 1];
    assert(n.length == 1);
    assert(n[0] is bi);
    foreach(Node nn; n){
        assert(nn.type == BencodeType.Integer);
    }
    assert(n.getBencode() == "li2ee");

    DictNode di = new DictNode();
    di["integer"] = bi;
    assert(di.length == 1);
    Node * np = "integer" in di;
    assert(np != null);
    np = "empty" in di;
    assert(np == null);
    di["string"] = si;
    assert(di.length == 2);
    n = di;
    assert(n.length == 2);
    di.remove("integer");
    assert(di.length == 1);
    di["integer"] = bi;
    assert(di.length == 2);
    n.remove("integer");
    assert(n.length == 1);
    n["integer"] = bi;
    assert(n.length == 2);
    assert(di.getBencode() == "d7:integeri2e6:string5:jelloe");
    assert(n.getBencode() == "d7:integeri2e6:string5:jelloe");
    foreach(k,v; di){
        if(k == "integer"){
            assert(v.type == BencodeType.Integer);
        }
        else if(k == "string"){
            assert(v.type == BencodeType.String);
        }
    }

    foreach(k,v; n){
        if(k == "integer"){
            assert(v.type == BencodeType.Integer);
        }
        else if(k == "string"){
            assert(v.type == BencodeType.String);
        }
    }
} 
