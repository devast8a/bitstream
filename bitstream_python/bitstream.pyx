import cython

cdef int64 UNIT_SIZE = 8
cdef int64 UNIT_OFFSET = UNIT_SIZE - 1

cdef class State:
    def __init__(State self, BitStream stream):
        self.offsetRead = stream.offsetRead
        self.offsetWrite = stream.offsetWrite
        self.stream = stream

class ReadError(Exception):
    def __init__(self, message):
        Exception.__init__(self, message)

class WriteError(Exception):
    def __init__(self, message):
        Exception.__init__(self, message)

cdef class BitStream:
    def __init__(self, stream = None):
        self.database = defaultFactory.database

        if stream == None:
            self.stream = []
            self.offsetRead = 0
            self.offsetWrite = 0
        else:
            self.stream = stream
            self.offsetRead = 0
            self.offsetWrite = len(stream) * 8

    def __len__(self):
        return self.offsetWrite - self.offsetRead

    cpdef write(BitStream self, value, type key, int count = -1):
        cdef TypeInfo typeinfo = self.database[key]
        cdef validator = typeinfo.validator
        cdef writer = typeinfo.writer
        cdef int64 byte
        cdef int64 bit

        if count == -1:
            byte = self.offsetWrite / UNIT_SIZE
            bit = self.offsetWrite % UNIT_SIZE

            if validator and not validator(value):
                raise WriteError("Input did not validate")

            writer(self, value, byte, bit)

            # Advance pointer
            self.offsetWrite += typeinfo.length
        else:
            if count < 0:
                raise WriteError("Invalid count specified")

            if count > len(value):
                raise WriteError("Count is greater than the length of the input")

            for i in range(count):
                byte = self.offsetWrite / UNIT_SIZE
                bit = self.offsetWrite % UNIT_SIZE

                if validator and not validator(value[i]):
                    raise WriteError("Input did not validate")

                writer(self, value[i], byte, bit)

                # Advance pointer
                self.offsetWrite += typeinfo.length

    cpdef read(BitStream self, type key, int count = -1):
        cdef TypeInfo typeinfo = self.database[key]
        cdef State state
        cdef int64 byte
        cdef int64 bit

        output = []

        # Allow the reader to read an arbitrary number of bits
        #   from the stream. In order to properly recover we save
        #   our state and restore it in the event of a underrun
        #   exception.
        if typeinfo.length == -1:
            raise NotImplementedError("Types with an arbitrary size aren't properly support yet")

            state = self.save()
            output = []
            try:
                for i in range(count):
                    output.append(typeinfo.reader(self))
            except:
                self.restore(state)
                raise
            return output

        # Otherwise, If the reader knows ahead of time how much data it
        #   will consume, we can take control of the pointers, knowing
        #   if we're going to underrun before we read. So we don't have
        #   to save our state.
        else:
            # If no count was specified, read only a single object from the
            #    stream and directly return it.
            if count == -1:
                # Check for underrun
                if self.offsetRead + typeinfo.length > self.offsetWrite:
                    raise ReadError("end of stream")

                byte = self.offsetRead / UNIT_SIZE
                bit = self.offsetRead % UNIT_SIZE

                output = typeinfo.reader(self, byte, bit)

                # Advance pointer
                self.offsetRead += typeinfo.length

                return output

            # Return an array
            else:
                if count < 0:
                    raise ReadError("Invalid count specified")

                # Check for underrun
                if self.offsetRead + (typeinfo.length * count) > self.offsetWrite:
                    raise ReadError("end of stream")

                output = []
                for i in range(count):
                    byte = self.offsetRead / UNIT_SIZE
                    bit = self.offsetRead % UNIT_SIZE

                    output.append(typeinfo.reader(self, byte, bit))

                    # Advance pointer
                    self.offsetRead += typeinfo.length
                return output

    cpdef seekTo(BitStream self, list searchFor):
        stream = self.stream
        cdef int32 byte = self.offsetRead / UNIT_SIZE
        cdef int32 bit = self.offsetRead % UNIT_SIZE
        cdef uint8 s1
        cdef uint8 s2


        # Ensure there's enough data to compare with what we're searching for
        if self.offsetWrite < (self.offsetRead + 8):
            # Move to end of stream if nothing found
            self.offsetRead = self.offsetWrite
            return

        # There's some number of bits that can be read
        if self.offsetWrite > (self.offsetRead + 8):
            s1 = stream[byte]
            s2 = stream[byte + 1]

            while self.offsetRead < self.offsetWrite - 8:
                if bit == 8:
                    bit = 0
                    byte += 1

                    s1 = s2
                    s2 = stream[byte + 1]

                value = (s1 << bit) | (s2 >> (8 - bit)) & 0xFF

                for search in searchFor:
                    if value == search:
                        return True

                bit += 1
                self.offsetRead += 1

            # Check the last byte
            if bit == 8:
                value = s2 & 0xFF
            else:
                value = (s1 << bit) | (s2 >> (8 - bit)) & 0xFF
            for search in searchFor:
                if value == search:
                    return True
        else:
            if bit == 0:
                value = stream[byte] & 0xFF
            else:
                value = (stream[byte] << bit) | (stream[byte + 1] >> (8 - bit)) & 0xFF
            for search in searchFor:
                if value == search:
                    return True

        return False

    cpdef readInt(BitStream self, int size, int count = 1):
        pass

    cpdef void seek(BitStream self, int64 offset):
        self.offsetRead += offset

    cpdef State save(BitStream self):
        return State(self)

    cpdef void restore(BitStream self, State state):
        if state.stream != self:
            raise Exception("State is not registered to this bitstream")

        self.offsetRead = state.offsetRead
        self.offsetWrite = state.offsetWrite

cdef class TypeInfo:
    def __init__(
        TypeInfo self,
        object key,
        int32 length = -1,
        reader = None,
        validator = None,
        writer = None,
    ):
        self.key = key
        self.length = length
        self.reader = reader
        self.writer = writer
        self.validator = validator

cdef class BitStreamFactory:
    def __init__(self):
        self.database = {}

    cpdef void register(BitStreamFactory self, TypeInfo typeinfo):
        self.database[typeinfo.key] = typeinfo
        return

cdef BitStreamFactory defaultFactory = BitStreamFactory()
