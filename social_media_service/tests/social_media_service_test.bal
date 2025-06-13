import ballerina/test;
import ballerina/http;
import ballerinax/mysql;

@test:Mock {
    functionName: "initSocialMediaDB"
}
function initMockSocialMediaDB() returns mysql:Client|error {
    return test:mock(mysql:Client);
}

@test:Config{}
function getUserById() returns error? {
    User userExpected = { id: 999, name: "foo", birthDate: {year: 0, month: 0, day: 0}, mobileNumber: "1234567890"};
    test:prepare(socialMediaDB).when("queryRow").thenReturn(userExpected);

    http:Client socialMediaEndpoint = check new("localhost:9090/social-media");
    User userActual = check socialMediaEndpoint->/users/[userExpected.id.toString()];

    test:assertEquals(userActual, userExpected);
}