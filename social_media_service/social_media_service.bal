import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
// import ballerina/regexp;

type User record {|
    @sql:Column {name: "id"}
    readonly int id;
    @sql:Column {name: "name"}
    string name;
    @sql:Column {name: "birth_date"}
    time:Date birthDate;
    @sql:Column {name: "mobile_number"}
    string mobileNumber;
|};

table<User> key(id) users = table [
    {id: 1, name: "Joe", birthDate: {year: 1990, month: 1, day: 1}, mobileNumber: "1234567890"}
];

type ErrorDetails record {
    string message;
    string details;
    time:Utc timestamp;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type DatabseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DatabseConfig dbConfig = {
    host: "localhost",
    user: "root",
    password: "Castroaterice2day",
    database: "social_media_database",
    port: 3306
};

mysql:Client socialMediaDB = check new (
    ...dbConfig
);

type Post record {|
    @sql:Column {name: "id"}
    readonly int id;
    @sql:Column {name: "description"}
    string description;
    @sql:Column {name: "category"}
    string category;
    @sql:Column {name: "created_date"}
    time:Date createdDate;
    @sql:Column {name: "tags"}
    string tags;
    @sql:Column {name: "user_id"}
    int userId;
|};

service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDB->query(`SELECT * FROM users`);
        return from var user in userStream
            select user;
    }

    resource function get users/[int id]() returns User|UserNotFound|error {

        User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id: ${id}`, details: string `user/${id}`, timestamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;

        // User? user = users[id];
        // if user is () {
        //     UserNotFound userNotFound = {
        //         body: {message: string `id: ${id}`, details: string `user/${id}`, timestamp: time:utcNow()}
        //     };
        //     return userNotFound;
        // }
        // return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {

        transaction {

            _ = check socialMediaDB->execute(
            `INSERT INTO users(name, birth_date, mobile_number) 
             VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber})`
            );
            _ = check socialMediaDB->execute(
            `INSERT INTO followers(name, birth_date, mobile_number) 
             VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber})`);

            check commit;
        }

        // Insert user into users table

        return http:CREATED;
    };

    resource function get posts() returns Post[]|error {
        stream<Post, sql:Error?> postStream = socialMediaDB->query(`SELECT * FROM posts`);
        return from var post in postStream
            select post;
    }

    // resource function to get the posts with their respective id
    resource function get posts/[int id]() returns Post|error {
        Post|sql:Error post = socialMediaDB->queryRow(`SELECT * FROM posts WHERE id = ${id}`);
        return post;
    }

    # Get posts for a give user
    #
    # + id - The user ID for which posts are retrieved
    # + return - A list of posts or error message
    resource function get users/[int id]/posts() returns PostWithMeta[]|UserNotFound|error {
        User|error result = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if result is sql:NoRowsError {
            ErrorDetails errorDetails = buildErrorPayload(string `id: ${id}`, string `users/${id}/posts`);
            UserNotFound userNotFound = {
                body: errorDetails
            };
            return userNotFound;
        }

        stream<Post, sql:Error?> postStream = socialMediaDB->query(`SELECT id, description, category, created_date, tags FROM posts WHERE user_id = ${id}`);
        Post[]|error posts = from Post post in postStream
            select post;
        return postToPostWithMeta(check posts);
    }

};

type Created_date record {|
    int year;
    int month;
    int day;
|};

type Meta record {|
    string[] tags;
    string category;
    Created_date created_date;
|};

type PostWithMeta record {|
    int id;
    string description;
    Meta meta;
|};

function postToPostWithMeta(Post[] post) returns PostWithMeta[] => from var postItem in post
    select {
        id: postItem.id,
        description: postItem.description,
        meta: {
            //tags: regexp:split(re `,`, postItem.tags),
            tags: [postItem.tags],
            category: postItem.category,
            created_date: {
                year: postItem.createdDate.year,
                month: postItem.createdDate.month,
                day: postItem.createdDate.day
            }
        }
    };


function buildErrorPayload(string msg, string path) returns ErrorDetails => {
    message: msg,
    timestamp: time:utcNow(),
    details: string `uri=${path}`
};
