type Contact record {
    string description;
    string firstName;
    string lastName;
    string title;
    string phone;
    string email;
    string id;
};

function getContact(string[] arr) returns Contact {
    Contact contact = {
        description: arr[0],
        firstName: arr[1],
        lastName: arr[2],
        title: arr[3],
        phone: arr[4],
        email: arr[5],
        id: arr[6]
    };
    return contact;
}