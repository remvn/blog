---
title: Gotcha of custom type in go-validator
date: "2024-09-24T19:14:28+07:00"
draft: false
showComments: true
description: "Gotcha of custom type in go-validator and how to fix it"
tags:
- golang
- random
---

Source code of this article can be found here:
[Github repo](https://github.com/remvn/go-validator-custom-type)

## What's go-validator?

From it's [repo](https://github.com/go-playground/validator):
> 100+ Struct and Field validation, including Cross Field, Cross Struct, Map,
> Slice and Array diving

One common use-case you may think of is validating `request body` of an API
Endpoint

```go
func makeValidator() *validator.Validate {
	validate := validator.New(validator.WithRequiredStructEnabled())
	return validate
}

func TestSimpleStruct(t *testing.T) {
	// check `Name` length is greater than 10
	type requestBody struct {
		Name string `validate:"required,gt=10"`
	}
	validate := makeValidator()

	body := &requestBody{
		Name: "short",
	}

	err := validate.Struct(body)
	assert.Error(t, err, "should raise an error because name is less than 10")
}
```

## Gotcha of custom type 

Go's lack of `nullability` makes us rely on some alternatives to represent
`nullability` in Golang {{< emoji "beat_brick" >}}. Two methods I know of are:
- Pointer 
- Custom struct with a `Valid` field (check this type at [std
  library](https://pkg.go.dev/database/sql#NullString))

If you happen to need the use of `nullability` and you see this:
> `go-validator` README<br>
> Handles custom field types such as sql driver Valuer see
> [Valuer](https://go.dev/src/database/sql/driver/types.go?s=1210:1293#L29)

Then you might think it has support for anything that implements interface
`driver.Valuer` out of the box, like `sql.NullString` which I mentioned earlier

But those simple unit-tests say otherwise:

### 1st test

```go
func TestNullField(t *testing.T) {
	validate := makeValidator()

	type testCase struct {
		Name sql.NullString `validate:"required"`
	}
	test := &testCase{
		Name: sql.NullString{
			String: "Hello", // This is not empty on purpose,
			//	I will explain it later
			Valid: false, // Valid = false represents null
		},
	}

	err := validate.Struct(test)
	// check err is not nil
	assert.Error(t, err, "should return an error because name is null")
}
```

Test result:
```bash
go test ./... -v
=== RUN   TestNullField
    main_test.go:31:
                Error Trace:    /home/remvn/personal/go-validator-custom-type/main_test.go:31
                Error:          An error is expected but got nil.
                Test:           TestNullField
                Messages:       should return an error because Valid is false
--- FAIL: TestNullField (0.00s)
=== RUN   TestSimpleStruct
--- PASS: TestSimpleStruct (0.00s)
FAIL
FAIL    github.com/remvn/go-validator-custom-type       0.002s
FAIL
```

The test failed, `err` returned from validate function is nil even though Valid
= false

### 2nd test

In this test. We created a non-null string with `Valid` being true, we also
added another validate tag: `gt=10` (check if the length is greater than 10)

```go
func TestFieldLength(t *testing.T) {
	validate := makeValidator()

	type testCase struct {
		Name sql.NullString `validate:"required,gt=10"`
	}
	test := &testCase{
		// This is a non-null string
		Name: sql.NullString{
			String: "hello", // note that string length is less than 10
			Valid:  true,
		},
	}

	err := validate.Struct(test)
	// check err is not nil
	assert.Error(t, err, "should return an error because length is less than 10")
}
```

The test even result with `panic`: 
```bash
go test -run TestFieldLength -v ./...
=== RUN   TestFieldLength
--- FAIL: TestFieldLength (0.00s)
panic: Bad field type sql.NullString [recovered]
        panic: Bad field type sql.NullString

goroutine 7 [running]:
testing.tRunner.func1.2({0x63e2a0, 0xc00002b200})
```

## What's going on? Can we fix this?

After some digging. Turns out this library didn't handle `driver.Valuer` out of
the box {{< emoji "canny" >}}. It also explains why: 

1. The [first test](#1st-test) is failing because by default `go-validator`
   treats `Name` field as a normal struct. So, with a `required` tag on that
   struct, it tried to check every field of that struct, the check will pass if
   one of them is not zero-value. This is also why I put a non-empty string on
   purpose to make the test failing, proving that `Valid = false` means
   nothing.<br>
   * Have a read about `required` tag here:
     [docs](https://pkg.go.dev/github.com/go-playground/validator/v10#hdr-Required)

2. With the knowledge above, it's easier to understand why [second
   test](#2nd-test) is failing, since now it tried to check **"the length of the
   struct is greater than 10"**, which ultimately panic by default

To use custom types for `go-validator` you need to register a custom function
to <mark>pull out the "real" value of the struct manually.</mark>

Here's how we can do it: 
```go
func makeValidator() *validator.Validate {
	validate := validator.New(validator.WithRequiredStructEnabled())

	// register func for custom struct, do this for every custom struct
	// you're going to need
	validate.RegisterCustomTypeFunc(validateValuer, sql.NullString{}, sql.NullInt64{})
	return validate
}

func validateValuer(field reflect.Value) interface{} {
	if valuer, ok := field.Interface().(driver.Valuer); ok {
		val, err := valuer.Value()
		if err == nil {
			// return the "real" value of custom struct
			// for example: if concrete type of driver.Valuer interface
			// is sql.NullString then val will be a string
			return val
		}
	}
	// return nil means this field is indeed "null".
	// field with tag `required` will fail the check
	return nil
}
```

Now the tests are passing: 
```bash
go test -v ./...
=== RUN   TestNullField
--- PASS: TestNullField (0.00s)
=== RUN   TestFieldLength
--- PASS: TestFieldLength (0.00s)
=== RUN   TestSimpleStruct
--- PASS: TestSimpleStruct (0.00s)
PASS
ok      github.com/remvn/go-validator-custom-type       0.002s
```

I think this is a small lack of documentation of `go-validator`, which can be
hard to figure out. But overall this is a good opportunity for me to understand
the language specs a little bit deeper. 

